# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykSignerUnix < Formula
  url "file:///dev/null"
  version "v20.1-2"

  depends_on "mavryk-signer"

  desc "Meta formula that provides backround mavryk-signer service that runs over unix socket"

  def install
    startup_contents =
      <<~EOS
      #!/usr/bin/env bash

      set -euo pipefail

      signer="/usr/local/bin/mavkit-signer"

      if [[ -n $PIDFILE ]]; then
        pid_file_args=("--pid-file" "$PIDFILE")
      else
        pid_file_args=()
      fi

      if [[ -n $MAGIC_BYTES ]]; then
        magic_bytes_args=("--magic-bytes" "$MAGIC_BYTES")
      else
        magic_bytes_args=()
      fi

      if [[ -n $CHECK_HIGH_WATERMARK ]]; then
        check_high_watermark_args=("--check-high-watermark")
      else
        check_high_watermark_args=()
      fi

      "$signer" -d "$MAVRYK_CLIENT_DIR" launch local signer --socket "$SOCKET" \
        ${pid_file_args[@]+"${pid_file_args[@]}"} ${magic_bytes_args[@]+"${magic_bytes_args[@]}"} \
        ${check_high_watermark_args[@]+"${check_high_watermark_args[@]}"} "$@"
    EOS
    File.write("mavryk-signer-unix-start", startup_contents)
    bin.install "mavryk-signer-unix-start"
  end

  service do
    run opt_bin/"mavryk-signer-unix-start"
    require_root true
    environment_variables MAVRYK_CLIENT_DIR: var/"lib/mavryk/client", SOCKET: var/"lib/mavryk/signer-unix", PIDFILE: "", MAGIC_BYTES: "", CHECK_HIGH_WATERMARK: ""
    log_path var/"log/mavryk-signer-unix.log"
    error_log_path var/"log/mavryk-signer-unix.log"
  end

  def post_install
    mkdir "#{var}/lib/mavryk/signer-unix"
  end
end