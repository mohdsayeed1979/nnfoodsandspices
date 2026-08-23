import type { Config } from 'tailwindcss';

const config: Config = {
  content: ['./src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          green: '#5E9C2C',
          greenDark: '#3D6E18',
          greenLight: '#8BC34A',
          orange: '#F36B21',
          orangeLight: '#FF9E54',
          cream: '#FDFBF6',
        },
      },
      fontFamily: {
        sans: ['ui-sans-serif', 'system-ui', 'Segoe UI', 'Roboto', 'Helvetica', 'Arial', 'sans-serif'],
        display: ['Georgia', 'Cambria', '"Times New Roman"', 'serif'],
      },
      boxShadow: {
        soft: '0 8px 30px rgba(0,0,0,0.06)',
        card: '0 4px 20px rgba(0,0,0,0.05)',
      },
    },
  },
  plugins: [],
};

export default config;
