/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  swcMinify: true,
  images: {
    domains: ['avatars.githubusercontent.com', 'lh3.googleusercontent.com'],
  },
  // Configure development server to use port 3007 by default
  // Note: When running with 'npm run dev', you can still override this with '-p PORT'
  serverRuntimeConfig: {
    port: parseInt(process.env.PORT, 10) || 3007,
  },
  // Enable rewrites to ensure API proxy works correctly
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: '/api/:path*',
      },
    ];
  },
  async redirects() {
    return [
      {
        source: '/',
        destination: '/dashboard',
        permanent: true,
      },
    ];
  },
  // Output standalone for production deployments
  output: 'standalone',
};

module.exports = nextConfig;
