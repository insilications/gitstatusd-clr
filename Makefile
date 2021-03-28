APPNAME ?= gitstatusd
OBJDIR ?= obj

CXX ?= g++
ZSH := $(shell command -v zsh 2> /dev/null)

VERSION ?= $(shell . ./build.info && printf "%s" "$$gitstatus_version")

# Note: -fsized-deallocation is not used to avoid binary compatibility issues on macOS.
#
# Sized delete is implemented as __ZdlPvm in /usr/lib/libc++.1.dylib but this symbol is
# missing in macOS prior to 10.13.
CXXFLAGS += -std=c++14 -funsigned-char -O3 -DNDEBUG -DGITSTATUS_VERSION=$(VERSION) -Wall -O3 --param=lto-max-streaming-parallelism=16 -march=native -mtune=native -fgraphite-identity -Wall -Wl,--as-needed -Wl,--build-id=sha1 -Wl,--enable-new-dtags -Wl,--hash-style=gnu -Wl,-O2 -Wl,-z,now -Wl,-z,relro -falign-functions=32 -flimit-function-alignment -fasynchronous-unwind-tables -fdevirtualize-at-ltrans -floop-nest-optimize -fno-math-errno -fno-semantic-interposition -fno-stack-protector -fno-trapping-math -ftree-loop-distribute-patterns -ftree-loop-vectorize -ftree-vectorize -funroll-loops -fuse-ld=bfd -fuse-linker-plugin -malign-data=cacheline -feliminate-unused-debug-types -fipa-pta -flto=16 -fno-plt -mtls-dialect=gnu2 -Wl,-sort-common -Wno-error -Wp,-D_REENTRANT -pipe -ffat-lto-objects -fPIC
LDFLAGS += -pthread -O3 --param=lto-max-streaming-parallelism=16 -march=native -mtune=native -fgraphite-identity -Wall -Wl,--as-needed -Wl,--build-id=sha1 -Wl,--enable-new-dtags -Wl,--hash-style=gnu -Wl,-O2 -Wl,-z,now -Wl,-z,relro -falign-functions=32 -flimit-function-alignment -fasynchronous-unwind-tables -fdevirtualize-at-ltrans -floop-nest-optimize -fno-math-errno -fno-semantic-interposition -fno-stack-protector -fno-trapping-math -ftree-loop-distribute-patterns -ftree-loop-vectorize -ftree-vectorize -funroll-loops -fuse-ld=bfd -fuse-linker-plugin -malign-data=cacheline -feliminate-unused-debug-types -fipa-pta -flto=16 -fno-plt -mtls-dialect=gnu2 -Wl,-sort-common -Wno-error -Wp,-D_REENTRANT -pipe -ffat-lto-objects
LDLIBS += -lgit2

SRCS := $(shell find src -name "*.cc")
OBJS := $(patsubst src/%.cc, $(OBJDIR)/%.o, $(SRCS))

all: $(APPNAME)

$(APPNAME): usrbin/$(APPNAME)

usrbin/$(APPNAME): $(OBJS)
	$(CXX) $(OBJS) $(LDFLAGS) $(LDLIBS) -o $@

$(OBJDIR):
	mkdir -p -- $(OBJDIR)

$(OBJDIR)/%.o: src/%.cc Makefile build.info | $(OBJDIR)
	$(CXX) $(CXXFLAGS) -MM -MT $@ src/$*.cc >$(OBJDIR)/$*.dep
	$(CXX) $(CXXFLAGS) -Wall -c -o $@ src/$*.cc

clean:
	rm -rf -- $(OBJDIR)

.PHONY: install
install:
	mkdir -p -m 755 $(DESTDIR)/usr/share/gitstatusd/usrbin
	cp usrbin/$(APPNAME) $(DESTDIR)/usr/share/gitstatusd/usrbin/$(APPNAME)
	cp gitstatus.plugin.sh $(DESTDIR)/usr/share/gitstatusd/gitstatus.plugin.sh
	cp gitstatus.prompt.sh $(DESTDIR)/usr/share/gitstatusd/gitstatus.prompt.sh
	cp install $(DESTDIR)/usr/share/gitstatusd/install
	cp build.info $(DESTDIR)/usr/share/gitstatusd/build.info
	cp install.info $(DESTDIR)/usr/share/gitstatusd/install.info

pkg:
	GITSTATUS_DAEMON= GITSTATUS_CACHE_DIR=$(shell pwd)/usrbin ./install -f
	$(or $(ZSH),:) -fc 'for f in *.zsh install; do zcompile -R -- $$f.zwc $$f || exit; done'

-include $(OBJS:.o=.dep)
