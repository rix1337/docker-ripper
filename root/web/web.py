# -*- coding: utf-8 -*-
# Ripper Web UI
# Projekt von https://github.com/rix1337

"""Ripper.

Usage:
  web.py [--port=<PORT>]
         [--prefix=<PREFIX>]
         [--log=<LOGFILE>]
         [--user=<USERNAME>]
         [--pass=<PASSWORD>]

Options:
  --port=<PORT>          Set the webserver's port
  --prefix=<PREFIX>      Set the webserver's path prefix (useful with reverse proxy)
  --log=<LOGFILE>        Set the location of the log file
  --user=<USERNAME>      Set the username for webserver (requires pass to be set)
  --pass=<PASSWORD>      Set the password for webserver (requires username to be set)
"""

import base64
import os
from functools import wraps

from docopt import docopt
from flask import Flask, request, redirect, send_from_directory, render_template, jsonify, Response
from waitress import serve


# Credits: https://stackoverflow.com/a/13790289
def tail(f, lines=1, _buffer=4098):
    """Tail a file and get X lines from the end"""
    # place holder for the lines found
    lines_found = []

    # block counter will be multiplied by buffer
    # to get the block size from the end
    block_counter = -1

    # loop until we find X lines
    while len(lines_found) < lines:
        try:
            f.seek(block_counter * _buffer, os.SEEK_END)
        except IOError:  # either file is too small, or too many lines requested
            f.seek(0)
            lines_found = f.readlines()
            break

        lines_found = f.readlines()

        # decrement the block counter to get the
        # next X bytes
        block_counter -= 1

    return lines_found[-lines:]


# Credits: https://stackoverflow.com/a/1094933
def sizeof_fmt(num, suffix="B"):
    for unit in ["", "Ki", "Mi", "Gi", "Ti", "Pi", "Ei", "Zi"]:
        if abs(num) < 1024.0:
            return f"{num:3.1f}{unit}{suffix}"
        num /= 1024.0
    return f"{num:.1f}Yi{suffix}"


def decode_base64(value):
    value = value.replace("-", "/")
    return base64.b64decode(value).decode()


def app_container():
    arguments = docopt(__doc__, version='Ripper')

    base_dir = '.'

    app = Flask(__name__, template_folder=os.path.join(base_dir, 'web'))
    app.config["TEMPLATES_AUTO_RELOAD"] = True

    if arguments['--port']:
        port = arguments['--port']
    else:
        port = 9090

    if arguments['--prefix']:
        prefix = arguments['--prefix']
        if not prefix[0] == '/':
            prefix = '/' + prefix
    else:
        prefix = ""

    if arguments['--log']:
        log_file = arguments['--log']
    else:
        log_file = "/config/Ripper.log"

    def check_auth(username, password):
        return username == arguments['--user'] and password == arguments['--pass']

    def authenticate():
        return Response(
            '''<html>
                <head><title>401 Authorization Required</title></head>
                <body bgcolor="white">
                <center><h1>401 Authorization Required</h1></center>
                <hr><center>FeedCrawler</center>
                </body>
                </html>
                ''', 401,
            {'WWW-Authenticate': 'Basic realm="FeedCrawler"'})

    def requires_auth(f):
        @wraps(f)
        def decorated(*args, **kwargs):
            if arguments['--user'] and arguments['--pass']:
                auth = request.authorization
                if not auth or not check_auth(auth.username, auth.password):
                    return authenticate()
            return f(*args, **kwargs)

        return decorated

    if prefix:
        @app.route('/')
        @requires_auth
        def index_prefix():
            return redirect(prefix)

    @app.route(prefix + '/<path:path>')
    @requires_auth
    def send_html(path):
        return send_from_directory(os.path.join(base_dir, 'web'), path)

    @app.route(prefix + '/')
    @requires_auth
    def index():
        return render_template('index.html')

    @app.route(prefix + "/api/log/", methods=['GET', 'DELETE'])
    @requires_auth
    def get_delete_log():
        if request.method == 'GET':
            try:
                log = []
                filesize = 0
                if os.path.isfile(log_file):
                    filesize = os.path.getsize(log_file)

                    log = tail(open(log_file, "r"), lines=100)[::-1]
                return jsonify(
                    {
                        "log": log,
                        "filesize": sizeof_fmt(filesize),
                        "large_file": filesize > 1000000
                    }
                )
            except:
                return "Failed", 400
        elif request.method == 'DELETE':
            try:
                open(log_file, 'w').close()
                return "Success", 200
            except:
                return "Failed", 400
        else:
            return "Failed", 405

    print("Ripper web log available on Port 9090")
    serve(app, host='0.0.0.0', port=port, threads=10, _quiet=True)


if __name__ == "__main__":
    app_container()
