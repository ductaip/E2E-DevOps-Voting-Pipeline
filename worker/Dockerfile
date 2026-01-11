# Stage 1: Build
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /source

COPY *.csproj .
RUN dotnet restore -r linux-x64

COPY . .
RUN dotnet publish -c release -o /app -r linux-x64 --self-contained true

# Stage 2: Runtime (Distroless)
# Using Ubuntu Chiseled (Distroless for .NET)
FROM mcr.microsoft.com/dotnet/runtime-deps:7.0-jammy-chiseled
WORKDIR /app

COPY --from=build /app .

# Non-root user is default in some distroless, but let's be explicit if possible or assume default.
# Mariner distroless runs as non-root (app) by default usually.

ENTRYPOINT ["./Worker"]
