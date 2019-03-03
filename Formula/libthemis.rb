class Libthemis < Formula
  desc 'High-level cryptographic primitives'
  homepage 'https://www.cossacklabs.com/themis'
  head 'https://github.com/cossacklabs/themis.git'
  url 'https://github.com/cossacklabs/themis/archive/0.10.0.tar.gz'
  sha256 '329a981e7e57a90107b330172b738104f7189cb20eac043d708c23c5db1570fb'

  depends_on 'openssl'

  def install
    ENV['ENGINE'] = 'openssl'
    ENV['ENGINE_INCLUDE_PATH'] = Formula['openssl'].include
    ENV['ENGINE_LIB_PATH'] = Formula['openssl'].lib
    ENV['PREFIX'] = prefix
    system 'make', 'install'
  end

  test do
    (testpath/'test.c').write <<~EOF
      #include <themis/themis.h>

      int main(void)
      {
          themis_status_t status = THEMIS_FAIL;
          size_t private_key_len = 0;
          size_t public_key_len = 0;

          status = themis_gen_ec_key_pair(
              NULL, &private_key_len,
              NULL, &public_key_len
          );

          return status == THEMIS_BUFFER_TOO_SMALL
              ? EXIT_SUCCESS
              : EXIT_FAILURE;
      }
    EOF
    system ENV.cc, 'test.c', '-o', 'test', "-I#{include}", "-L#{lib}", '-lthemis'
    system './test'
  end
end
