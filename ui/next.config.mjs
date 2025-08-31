/** @type {import('next').NextConfig} */
const nextConfig = {
  output: 'standalone', // ensure server.js + minimal node_modules emitted
  eslint: { ignoreDuringBuilds: true },
  typescript: { ignoreBuildErrors: true },
  images: { unoptimized: true },
}

export default nextConfig