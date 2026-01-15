# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenWebMail is a Perl-based webmail system derived from Neomail 1.14. Designed to handle very large mail folders efficiently, with features for users migrating from desktop clients like Outlook.

## Build and Run Commands

### Docker (Recommended)
```bash
docker build -t openwebmail .
docker run -p 8080:80 openwebmail
```

### Docker Compose
```bash
cp .env.example .env    # Configure IMAP/SMTP settings
docker-compose up --build
```
Access at http://localhost:8080/

### Run Tests
```bash
prove -l
```

### Initialize (non-Docker)
```bash
cgi-bin/openwebmail/openwebmail-tool.pl --init
```

### Test IMAP Authentication
```bash
perl misc/test/authtest.pl auth_imap.pl username password
```

## Architecture

### Directory Structure
```
cgi-bin/openwebmail/     # Main CGI scripts
├── openwebmail.pl       # Entry point
├── openwebmail-main.pl  # Main interface
├── openwebmail-read.pl  # Read messages
├── openwebmail-send.pl  # Compose/send
├── openwebmail-abook.pl # Address book
├── openwebmail-cal.pl   # Calendar
├── openwebmail-folder.pl# Folder management
├── openwebmail-tool.pl  # Admin/init tool
├── auth/                # Authentication modules
├── etc/                 # Configuration files
├── lib/                 # Perl libraries
└── modules/             # Feature modules

data/openwebmail/        # Static HTML/templates
t/                       # Test suite
```

### Authentication Modules
Located in `cgi-bin/openwebmail/auth/`:
- `auth_unix.pl` - Unix system authentication (default)
- `auth_imap.pl` - Remote IMAP server authentication

Configure via `auth_module` in `cgi-bin/openwebmail/etc/openwebmail.conf`

### Key Configuration Files
- `cgi-bin/openwebmail/etc/openwebmail.conf` - Main config (mailspooldir, ow_htmldir, ow_cgidir)
- `cgi-bin/openwebmail/etc/auth_unix.conf` - Unix auth settings
- `cgi-bin/openwebmail/etc/defaults/dbm.conf` - Database file settings

## Environment Variables (Docker)

```
IMAP_HOST, IMAP_PORT, IMAP_SSL
SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASSWORD
AUTH_MODULE          # e.g., auth_unix.pl or auth_imap.pl
```

## Code Style

- Perl scripts use `strict` and `warnings`
- CGI scripts are setuid root (chmod 4755) for mail spool access
