# frozen_string_literal: true

require "logger"
require "openssl"
require "socket"
require "websocket"
require_relative "websocket_client_lite/version"

class WebsocketClientLite
  attr_accessor :url, :logger, :incoming_queue, :handshake_object, :socket, :state

  def initialize(url, logger: nil)
    @url = url
    @logger = logger || Logger.new(File::NULL)
    @incoming_queue = Queue.new
    @state = nil
  end

  def handshake
    @state = :connecting
    @handshake_object = WebSocket::Handshake::Client.new(url: @url)
    @socket = make_socket(@handshake_object.host, @handshake_object.port, @handshake_object.secure)
    @socket.write(@handshake_object.to_s)

    until @handshake_object.finished?
      byte = @socket.read(1)
      @handshake_object << byte
    end

    @handshake_object.valid?
    @state = :open
    true
  rescue StandardError => e
    @logger.error("Handshake failed: #{e.inspect}")
    @socket&.close
    @socket = nil
    @state = nil
    false
  end

  def each_payload(&block)
    thread = nil
    return unless @state == :open

    thread = start_incoming_thread

    while %i[open closing_by_client].include?(@state) do
      frame = @incoming_queue.pop
      case frame.type
      when :ping
        send_pong(frame.data)
      when :pong
        # no-op
      when :text, :binary
        block.yield(frame.data)
      when :close
        if @state == :open
          @state = :closing_by_server
          send_close(frame.data)
        end
        @state = :closed
      else
        raise "Unknown frame. type: #{frame.type}, data: #{frame.data}"
      end
    end
  ensure
    thread&.join(1)
    @socket&.close
    @socket = nil
    @state = nil
  end

  def close(code = nil, data = nil)
    if @state == :open
      @state = :closing_by_client
      send_frame(:close, data, code: code)
    end
  end

  def send_ping(code, data)
    send_frame(:ping, data, code: code)
  end

  def send_pong(data)
    send_frame(:pong, data)
  end

  def send_close(code)
    send_frame(:close, nil, code: code)
  end

  def send_text(data)
    send_frame(:text, data)
  end

  def send_binary(data)
    send_frame(:binary, data)
  end

  private

  def make_socket(host, port, secure)
    socket = Socket.tcp(host, port)
    socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_KEEPALIVE, true)
    if secure
      socket = OpenSSL::SSL::SSLSocket.new(socket)
      socket.connect
      socket.post_connection_check(host)
      socket.sync_close = true
    end
    socket
  end

  def start_incoming_thread
    Thread.start(@socket, @incoming_queue, @logger) do |socket, incoming_queue, logger|
      frame_processor = WebSocket::Frame::Incoming::Client.new
      until socket.closed?
        binary = socket.readpartial(4096)
        frame_processor << binary
        while (frame = frame_processor.next)
          logger.debug("[ws incoming] type: #{frame.type}, code: #{frame.code}, data: #{frame.data}")
          incoming_queue << frame
        end
      end
    rescue StandardError => e
      logger.error("[ws incoming] #{e.inspect}")
    end
  end

  def send_frame(type, data, code: nil)
    logger.debug("[ws outgoing] type: #{type}, code: #{code}, data: #{data}")
    frame = WebSocket::Frame::Outgoing::Client.new(data: data, type: type, code: code, version: @handshake_object.version)
    @socket.write(frame.to_s)
  end
end
