FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    gnupg \
    libglib2.0-0 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2t64 \
    libxshmfence1 \
    libx11-6 \
    libxcb1 \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    libglib2.0-0 \
    libcairo2 \
    libnss3 \
    libnspr4 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libcups2 \
    libdrm2 \
    libdbus-1-3 \
    libxkbcommon0 \
    libxcomposite1 \
    libxdamage1 \
    libxfixes3 \
    libxrandr2 \
    libgbm1 \
    libasound2t64 \
    libxshmfence1 \
    libx11-6 \
    libxcb1 \
    libxext6 \
    libxrender1 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    fonts-liberation \
    fonts-dejavu-core \
    wget \
    ca-certificates

RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
RUN apt-get update && apt-get install -y nodejs

WORKDIR /app

COPY . .

RUN npm install

EXPOSE 2785 2886

CMD ["npm", "run", "dev"]