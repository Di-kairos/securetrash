class Securetrash < Formula
  desc "Honest secure file deletion for macOS (FileVault + crypto-shred vaults)"
  homepage "https://github.com/Di-kairos/securetrash"
  url "https://github.com/Di-kairos/securetrash/archive/refs/tags/v0.4.5.tar.gz"
  sha256 "6fcd9274bf185491dc016630ec0036f64cf3132306bc5e78ab8f66134763c28b"
  license "MIT"

  def install
    bin.install "securetrash"
  end

  test do
    assert_match "securetrash", shell_output("#{bin}/securetrash version")
  end
end
