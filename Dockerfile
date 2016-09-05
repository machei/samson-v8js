FROM webdevops/samson-deployment

MAINTAINER contact@sponk.pl

RUN apt-get update
RUN apt-get -y install git subversion make g++ python curl php5-dev chrpath && apt-get clean

# depot tools
RUN git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git /usr/local/depot_tools
ENV PATH $PATH:/usr/local/depot_tools

# download v8
RUN cd /tmp && fetch v8

RUN export GYPFLAGS="-Dv8_use_external_startup_data=0"
RUN export GYPFLAGS="${GYPFLAGS} -Dlinux_use_bundled_gold=0"

# compile v8
RUN cd /tmp/v8 && make native library=shared snapshot=on -j8

# install v8
#RUN mkdir -p /usr/local/lib
#RUN cp /usr/local/src/v8/out/native/lib.target/lib*.so /usr/local/lib
#RUN echo -e "create /usr/lib/libv8_libplatform.a\naddlib out/native/obj.target/src/libv8_libplatform.a\nsave\nend" | sudo ar -M
#RUN echo "create /usr/local/lib/libv8_libplatform.a\naddlib /usr/local/src/v8/out/native/obj.target/tools/gyp/libv8_libplatform.a\nsave\nend" | ar -M#
#RUN cp -R /usr/local/src/v8/include /usr/local
#RUN chrpath -r '$ORIGIN' /usr/local/lib/libv8.so

# Install to /usr
RUN sudo mkdir -p /usr/local/lib /usr/local/include
RUN cd /tmp/v8 && cp out/native/lib.target/lib*.so /usr/local/lib/
RUN cd /tmp/v8 && cp -R include/* /usr/local/include

# Fix libv8.so's RUNPATH header
RUN sudo chrpath -r '$ORIGIN' /usr/local/lib/libv8.so

# Install libv8_libplatform.a (V8 >= 5.2.51)
RUN sudo echo -e "create /usr/local/lib/libv8_libplatform.a\naddlib /tmp/v8/out/native/obj.target/src/libv8_libplatform.a\nsave\nend" | sudo ar -M

# get v8js, compile and install
RUN rm -Rdf /tmp/v8js && git clone https://github.com/phpv8/v8js.git /tmp/v8js && cd /tmp/v8js && git checkout master
RUN cp /tmp/v8/out/native/snapshot_blob.bin /usr/local/lib/ && cp /tmp/v8/out/native/natives_blob.bin /usr/local/lib/
RUN cd /tmp/v8js && phpize && ./configure --with-v8js=/usr/local
ENV NO_INTERACTION 1
RUN cd /tmp/v8js && sudo make && sudo make install

# autoload v8js.so
RUN echo extension=v8js.so > /etc/php5/cli/conf.d/99-v8js.ini
