class Securetrash < Formula
  desc "Honest secure file deletion for macOS (FileVault + crypto-shred vaults)"
  homepage "https://github.com/Di-kairos/securetrash"
  url "https://github.com/Di-kairos/securetrash/archive/refs/tags/v0.4.3.tar.gz"
  sha256 "2de458e0085f5307c12a87f69e5c1bf1fd7c3c21abc82ac3b9dda0f2dd0b6d55"
  license "MIT"

  def install
    bin.install "securetrash"
  end

  test do
    assert_match "securetrash", shell_output("#{bin}/securetrash version")
  end
end
