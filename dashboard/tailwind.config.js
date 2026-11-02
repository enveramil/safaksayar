/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        dark: {
          bg: '#0B0D13',
          card: '#131620',
          border: '#1F2433',
          hover: '#1A1E2C',
        },
        brand: {
          primary: '#2563EB',
          accent: '#10B981',
          warning: '#F59E0B',
          danger: '#EF4444',
          pro: '#8B5CF6',
        }
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', '-apple-system', 'sans-serif'],
        mono: ['JetBrains Mono', 'monospace'],
      }
    },
  },
  plugins: [],
}

