import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  darkMode: 'class',
  theme: {
    extend: {
      fontFamily: {
        mono: ["'JetBrains Mono'", "'Space Mono'", "monospace"],
      },
      colors: {
        background: "#030712",
        foreground: "#e5e7eb",
      },
    },
  },
  plugins: [],
};
export default config;
