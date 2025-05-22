# OpenWebMail

OpenWebMail is a webmail system written in Perl. It is derived from
Neomail 1.14 and is designed to handle very large mail folders while
using memory efficiently. The project includes many features to help
users migrate from traditional desktop clients such as Microsoft
Outlook.

## Prerequisites

Before installing OpenWebMail you should have:

* An Apache (or compatible) web server with CGI enabled
* Perl 5.005 or later
* Required Perl modules:
  * CGI.pm
  * MIME-Base64
  * libnet
  * Digest and Digest::MD5
  * Text-Iconv (libiconv if your system lacks iconv)
* Optional modules for additional features: CGI::SpeedyCGI,
  Compress::Zlib, ispell, Quota, Authen::PAM and Net::SSLeay/OpenSSL

Detailed information about the required packages is available in
`docs/README.md`.

## Basic Installation

1. Extract the OpenWebMail distribution under your web server root so
   that the CGI scripts are available (for example under
   `cgi-bin/openwebmail`) and the static HTML files are placed in your
   document directory.
2. Edit `cgi-bin/openwebmail/etc/openwebmail.conf` and adjust settings
   such as `mailspooldir`, `ow_htmldir` and `ow_cgidir` for your
   environment. Depending on your authentication method you may also
   need to edit `auth_unix.conf`.
3. Run the initialization script:

   ```sh
   cgi-bin/openwebmail/openwebmail-tool.pl --init
   ```

This step builds the internal mapping tables required for the web
interface.

For a complete description of installation options, configuration files
and optional modules please read
[`docs/README.md`](docs/README.md).

## Tests

A basic test suite exists in the `t` directory, including a `compile.t`
script that ensures every module and utility script compiles.  Run the
tests with:

```sh
prove -l
```

## IMAP Support

An authentication module for remote IMAP servers is provided as
`auth_imap.pl`.  Enable it by setting `auth_module` in
`cgi-bin/openwebmail/etc/openwebmail.conf` and define the server
parameters `authimap_server`, `authimap_port` and `authimap_usessl`.
The helper script `misc/test/authtest.pl` can be used to verify a user
against the configured IMAP server:

```sh
perl misc/test/authtest.pl auth_imap.pl username password
```

## Docker Setup

A `Dockerfile` is provided for running OpenWebMail on a modern Ubuntu
system. Build the image with:

```sh
docker build -t openwebmail .
```

Run the container and expose port 80:

```sh
docker run -p 8080:80 openwebmail
```

The application will then be available at
`http://localhost:8080/`.

### Docker Compose

An example environment file is provided to make configuration easier. Copy
`.env.example` to `.env` and adjust the values for your IMAP and SMTP server.

Build and start the service with:

```sh
docker-compose up --build
```

The web interface will be available at `http://localhost:8080/`.

## Links

<http://openwebmail.acatysmoof.com/>

<https://openwebmail.org/>
