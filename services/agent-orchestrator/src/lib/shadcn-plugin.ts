
import plugin from "tailwindcss/plugin";
import { Config } from "tailwindcss";

// This plugin contains all the utilities needed for shadcn/ui components
export const shadcnPlugin = plugin(
  ({ addBase }) => {
    addBase({
      ":root": {
        "--sidebar": "0 0% 98%",
        "--sidebar-foreground": "240 5.3% 26.1%",
        "--sidebar-accent": "240 4.8% 95.9%",
        "--sidebar-accent-foreground": "240 5.9% 10%",
        "--sidebar-border": "220 13% 91%",
        "--sidebar-ring": "217.2 91.2% 59.8%",
      },
      ".dark": {
        "--sidebar": "225 30% 12%",
        "--sidebar-foreground": "240 4.8% 95.9%",
        "--sidebar-accent": "225 30% 18%",
        "--sidebar-accent-foreground": "240 4.8% 95.9%",
        "--sidebar-border": "225 30% 18%",
        "--sidebar-ring": "217.2 91.2% 59.8%",
      },
    });
  },
  {
    theme: {
      container: {
        center: true,
        padding: "2rem",
        screens: {
          "2xl": "1400px",
        },
      },
    },
  }
);

export default (config: Config) => {
  return {
    ...config,
    darkMode: ["class"],
    plugins: [...(config.plugins || []), shadcnPlugin],
  };
};
