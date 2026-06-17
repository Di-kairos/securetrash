class Securetrash < Formula
  desc "Honest secure file deletion for macOS (FileVault + crypto-shred vaults)"
  homepage "https://github.com/Di-kairos/securetrash"
  url "https://github.com/Di-kairos/securetrash/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "85023264c9ae1c286ab6065da2aa792190bed9dc8bda14d9ce9470bf29684b1b"
  license "MIT"

  def install
    bin.install "securetrash"
  end

  test do
    assert_match "securetrash", shell_output("#{bin}/securetrash version")
  end
end
