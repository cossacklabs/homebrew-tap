class Libthemis < Formula
  desc 'High-level cryptographic primitives'
  homepage 'https://www.cossacklabs.com/themis'
  head 'https://github.com/cossacklabs/themis.git'
  url 'https://github.com/cossacklabs/themis/archive/<%CL_THEMIS_VERSION%>.tar.gz'
  sha256 '<%CL_THEMIS_GITHUB_TARGZ_SHA256%>'

  depends_on 'openssl'

  option 'with-cpp', 'Install C++ header files for ThemisPP'
  option 'with-java', 'Install JNI library for JavaThemis'

  def install
    ENV['ENGINE'] = 'openssl'
    ENV['ENGINE_INCLUDE_PATH'] = Formula['openssl'].include
    ENV['ENGINE_LIB_PATH'] = Formula['openssl'].lib
    ENV['PREFIX'] = prefix
    system 'make', 'install'
    if build.with? 'cpp'
      system 'make', 'themispp_install'
    end
    if build.with? 'java'
      system 'make', 'themis_jni_install'
    end
  end

  def caveats
    if build.with? 'java'
      themis_jni_lib = 'libthemis_jni.dylib'
      java_library_paths = `
        java -XshowSettings:properties -version 2>&1 \
        | sed -E 's/^ +[^=]+ =/_&/' \
        | awk -v prop=java.library.path \
          'BEGIN { RS = "_"; IFS = " = " }
           { if($1 ~ prop) {
               for (i = 3; i <= NF; i++) {
                 print $i
               }
             }
           }'
      `
      <<~EOF
        Most Java installations do not include Homebrew directories into library
        search path. Here is current "java.library.path" in your system:

        #{java_library_paths.split("\n").map{|s| '    ' + s}.join("\n")}

        #{themis_jni_lib} has been installed into #{lib}.
        Make sure to either add #{lib} to "java.library.path",
        or move #{themis_jni_lib} to a location known by Java.

        Read more: https://docs.cossacklabs.com/pages/java-and-android-howto/

      EOF
    end
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
