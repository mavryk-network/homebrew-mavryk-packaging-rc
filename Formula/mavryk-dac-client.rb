# SPDX-FileCopyrightText: 2021 Oxhead Alpha
# SPDX-License-Identifier: LicenseRef-MIT-OA

class MavrykDacClient < Formula
  @all_bins = []

  class << self
    attr_accessor :all_bins
  end
  homepage "https://gitlab.com/mavryk-network/mavryk-protocol"

  url "https://gitlab.com/mavryk-network/mavryk-protocol.git", :tag => "mavkit-v20.1", :shallow => false

  version "v20.1-2"

  build_dependencies = %w[pkg-config coreutils autoconf rsync wget rustup-init cmake opam]
  build_dependencies.each do |dependency|
    depends_on dependency => :build
  end

  dependencies = %w[gmp hidapi libev protobuf sqlite mavryk-sapling-params]
  dependencies.each do |dependency|
    depends_on dependency
  end
  desc "A Data Availability Committee Mavryk client"

  bottle do
    root_url "https://github.com/mavryk-network/mavryk-packaging/releases/download/#{MavrykDacClient.version}/"
    sha256 cellar: :any, monterey: "48ac0e3f066fc0dd9e9940c5aa6cbd7f0f16458ca98be774b18f5c12d1f6c6ec"
    sha256 cellar: :any, arm64_monterey: "273099adbd8d4844e3837628281ed3efac0db982951ba4e805000e946ae78640"
  end

  def make_deps
    ENV.deparallelize
    ENV["CARGO_HOME"]="./.cargo"
    # Disable usage of instructions from the ADX extension to avoid incompatibility
    # with old CPUs, see https://gitlab.com/dannywillems/ocaml-bls12-381/-/merge_requests/135/
    ENV["BLST_PORTABLE"]="yes"
    # Force linker to use libraries from the current brew installation.
    # Workaround for https://github.com/mavryk-network/mavryk-packaging/issues/700
    ENV["LDFLAGS"] = "-L#{HOMEBREW_PREFIX}/lib"
    # Here is the workaround to use opam 2.0.9 because Mavryk is currently not compatible with opam 2.1.0 and newer
    arch = RUBY_PLATFORM.include?("arm64") ? "arm64" : "x86_64"
    system "rustup-init", "--default-toolchain", "1.71.1", "-y"
    system "opam", "init", "--bare", "--debug", "--auto-setup", "--disable-sandboxing"
    system ["source .cargo/env",  "make build-deps"].join(" && ")
  end

  def install_template(dune_path, exec_path, name)
    bin.mkpath
    self.class.all_bins << name
    system ["eval $(opam env)", "dune build #{dune_path}", "cp #{exec_path} #{name}"].join(" && ")
    bin.install name
    ln_sf "#{bin}/#{name}", "#{bin}/#{name.gsub("mavkit", "mavryk")}"
  end

  def install
    make_deps
    install_template "src/bin_dac_client/main_dac_client.exe",
                     "_build/default/src/bin_dac_client/main_dac_client.exe",
                     "mavkit-dac-client"
  end
end
