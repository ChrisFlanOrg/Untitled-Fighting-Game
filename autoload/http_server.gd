extends Node

static var crypto = Crypto.new()
# Generate 4096 bits RSA key.
static var key = crypto.generate_rsa(4096)
# Generate self-signed certificate using the given key.
static var cert = crypto.generate_self_signed_certificate(key, "CN=example.com,O=A Game Company,C=IT")

var server: TCPServer
var connection: StreamPeerTLS
var server_thread: Thread

var time: int
var req_pos: int
var req_buf: PackedByteArray

const HTTP_HEADER = """HTTP/1.1 200 OK\r
Content-Type: %s\r
\r
\r
"""

const NOT_FOUND = """HTTP/1.1 404 Not Found\r
\r
\r
"""

func _init():
	server = TCPServer.new()
	connection = StreamPeerTLS.new()
	server_thread = Thread.new()
	req_buf.resize(4096)

func _ready():
	start()

func start():
	server.stop()
	server.listen(8080)

	server_thread.start(_server_thread_poll.bind())

func _clear_client():
	connection = StreamPeerTLS.new()
	req_buf.fill(0)
	time = 0;
	req_pos = 0;

func mime_type_for_asset(asset):
	if (asset.ends_with(".html")):
		return "text/html; charset=utf-8"
	if (asset.ends_with(".js")):
		return "text/javascript; charset=utf-8"
	if (asset.ends_with(".css")):
		return "text/css; charset=utf-8"
	else:
		return "text/plain"

func filename_for_asset(asset):
	if (asset == "/"):
		return "/client.html"
	else:
		return asset

func _send_response():
	var lines = req_buf.get_string_from_utf8().split("\r\n")
	if (lines.size() < 4):
		pass

	var blocks = lines[0].split(" ")

	if (blocks.size() < 2):
		pass

	var filename = filename_for_asset(blocks[1])
	var mime_type = mime_type_for_asset(filename)

	var file = "web/out%s" % filename

	if (!FileAccess.file_exists(file)):
		connection.put_data(NOT_FOUND.to_utf8_buffer())
		return

	connection.put_data((HTTP_HEADER % mime_type).to_utf8_buffer())
	connection.put_data(FileAccess.get_file_as_bytes(file))

func _server_thread_poll():
	while true:
		poll()
		OS.delay_msec(50)

func poll():
	if (!server.is_listening()):
		return

	if (connection.get_status() == StreamPeerTCP.STATUS_NONE):
		if (!server.is_connection_available()):
			return
		var raw_connection = server.take_connection()
		connection = StreamPeerTLS.new()
		connection.accept_stream(raw_connection, TLSOptions.server(HttpServer.key, HttpServer.cert))
		time = Time.get_ticks_usec()

	if (Time.get_ticks_usec() - time > 1000000):
		_clear_client()
		return

	if (connection.get_status() != StreamPeerTCP.STATUS_CONNECTED):
		return

	while (true):
		var l = req_pos - 1;
		if (l > 3):
			var cm0 = String.chr(req_buf[l-0])
			var cm1 = String.chr(req_buf[l-1])
			var cm2 = String.chr(req_buf[l-2])
			var cm3 = String.chr(req_buf[l-3])
			if (cm0 == '\n' && cm1 == '\r' && cm2 == '\n' && cm3 == '\r'):
				_send_response();
				_clear_client();
				return;

		# ERR_FAIL_COND(req_pos >= 4096)
		var result = connection.get_partial_data(1)
		var err = result[0]
		var partial_data = result[1]
		if (err != OK):
			# Got an error
			_clear_client();
			return;
		elif (partial_data.size() != 1):
			# Busy, wait next poll
			return
		req_buf[req_pos] = partial_data[0]
		req_pos += partial_data.size();

func stop():
	server.stop()
