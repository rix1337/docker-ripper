# -*- coding: utf-8 -*-
# Ripper Web UI
# Projekt von https://github.com/rix1337

"""Ripper.

Usage:
  web.py [--port=<PORT>]
         [---prefix=<PREFIX>]
         [---user=<USERNAME>]
         [--pass=<PASSWORD>]

Options:
  --port=<PORT>          Set the webserver's port
  --prefix=<PREFIX>      Set the webserver's path prefix (useful with reverse proxy)
  --user=<USERNAME>      Set the username for webserver (requires pass to be set)
  --pass=<PASSWORD>      Set the password for webserver (requires username to be set)
"""

import os
import re
from functools import wraps

import docopt
from flask import Flask, request, redirect, send_from_directory, render_template, jsonify, Response
from waitress import serve


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
                if os.path.isfile("/config/Ripper.log"):
                    logfile = open("/config/Ripper.log")
                    i = 0
                    for line in reversed(logfile.readlines()):
                        if line and line != "\n":
                            payload = [i]
                            line = line.replace("]", "")
                            line = line.replace("[", "")
                            line = re.sub(r",\d{3}", "", line)
                            line = line.split(" - ")
                            for line_part in line:
                                payload.append(line_part)
                            log.append(payload)
                        i += 1
                return jsonify(
                    {
                        "log": log,
                    }
                )
            except:
                return "Failed", 400
        elif request.method == 'DELETE':
            try:
                open(internal.log_file, 'w').close()
                return "Success", 200
            except:
                return "Failed", 400
        else:
            return "Failed", 405

    @app.route(prefix + "/api/log_entry/<b64_entry>", methods=['DELETE'])
    @requires_auth
    def get_delete_log_entry(b64_entry):
        if request.method == 'DELETE':
            try:
                entry = decode_base64(b64_entry)
                log = []
                if os.path.isfile(internal.log_file):
                    logfile = open(internal.log_file)
                    for line in reversed(logfile.readlines()):
                        if line and line != "\n":
                            if entry not in line:
                                log.append(line)
                    log = "".join(reversed(log))
                    with open(internal.log_file, 'w') as file:
                        file.write(log)
                return "Success", 200
            except:
                return "Failed", 400
        else:
            return "Failed", 405

    serve(app, host='0.0.0.0', port=port, threads=10, _quiet=True)


if __name__ == "__main__":
    app_container()
