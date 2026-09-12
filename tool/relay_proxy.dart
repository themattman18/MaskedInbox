import 'dart:convert';
import 'dart:io';

const relayOrigin = 'https://relay.firefox.com';
const defaultPort = 8787;

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.parse(args.first) : defaultPort;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  final client = HttpClient();

  stdout.writeln('Firefox Relay proxy listening on http://localhost:$port');
  stdout.writeln('Forwarding /api/* requests to $relayOrigin');

  await for (final request in server) {
    await _handleRequest(request, client);
  }
}

Future<void> _handleRequest(HttpRequest request, HttpClient client) async {
  final origin = request.headers.value('origin') ?? '*';
  _addCorsHeaders(request.response, origin);

  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }

  if (!request.uri.path.startsWith('/api/')) {
    request.response.statusCode = HttpStatus.notFound;
    request.response.write('Only /api/* paths are proxied.');
    await request.response.close();
    return;
  }

  try {
    final targetUri = Uri.parse(relayOrigin).replace(
      path: request.uri.path,
      query: request.uri.query,
    );
    final proxyRequest = await client.openUrl(request.method, targetUri);

    request.headers.forEach((name, values) {
      if (_hopByHopHeaders.contains(name.toLowerCase())) return;
      proxyRequest.headers.set(name, values);
    });

    final body = await request.fold<List<int>>(
      <int>[],
      (bytes, chunk) => bytes..addAll(chunk),
    );
    if (body.isNotEmpty) proxyRequest.add(body);

    final relayResponse = await proxyRequest.close();
    request.response.statusCode = relayResponse.statusCode;

    relayResponse.headers.forEach((name, values) {
      if (_hopByHopHeaders.contains(name.toLowerCase())) return;
      request.response.headers.set(name, values);
    });
    _addCorsHeaders(request.response, origin);

    await relayResponse.pipe(request.response);
  } catch (error) {
    request.response.statusCode = HttpStatus.badGateway;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({
      'error': 'Firefox Relay proxy request failed.',
      'details': error.toString(),
    }));
    await request.response.close();
  }
}

void _addCorsHeaders(HttpResponse response, String origin) {
  response.headers.set(HttpHeaders.accessControlAllowOriginHeader, origin);
  response.headers.set(
    HttpHeaders.accessControlAllowMethodsHeader,
    'GET, POST, PUT, PATCH, DELETE, OPTIONS',
  );
  response.headers.set(
    HttpHeaders.accessControlAllowHeadersHeader,
    'Authorization, Content-Type, Accept',
  );
}

const _hopByHopHeaders = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailer',
  'transfer-encoding',
  'upgrade',
  'host',
};
