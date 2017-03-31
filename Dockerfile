# Start with 0.5.0 which is also latest at the moment
FROM julia:0.5.0

# Install stuff needed by the HttpParser package
RUN apt-get update && apt-get install -y \
    zip \
    unzip \
    build-essential \
    make \
    gcc \
    libzmq3-dev

# Make package folder and install everything in require
ENV JULIA_PKGDIR=/opt/julia
RUN julia -e "Pkg.init()"
COPY REQUIRE /opt/julia/v0.5/REQUIRE
RUN julia -e "Pkg.resolve()"

# Build all the things
RUN julia -e 'Pkg.build()'

# Force precompile of all modules -- this should greatly improve startup time
RUN julia -e 'using Mux, HttpCommon, JSON'

COPY server.jl server.jl

# Don't run as root
RUN useradd -ms /bin/bash myuser
RUN chown -R myuser:myuser /opt/julia
USER myuser

# Get the party started
CMD julia server.jl $PORT
