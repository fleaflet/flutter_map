const lightCodeTheme = require("prism-react-renderer/themes/github");
const darkCodeTheme = require("prism-react-renderer/themes/dracula");

/** @type {import('@docusaurus/types').DocusaurusConfig} */
module.exports = {
  presets: [
    [
      "@docusaurus/preset-classic",
      {
        docs: {
          path: "../docs",
          routeBasePath: "/",
          sidebarPath: require.resolve("./sidebars.js"),
          editUrl:
            "https://github.com/fleaflet/flutter_map/edit/master/website/",
        },
        theme: {
          customCss: require.resolve("./src/css/custom.css"),
        },
      },
    ],
  ],
  title: "flutter_map",
  tagline: "A port of leaflet.js for Flutter",
  url: "https://flutter-map.vercel.app",
  baseUrl: "/",
  onBrokenLinks: "throw",
  onBrokenMarkdownLinks: "warn",
  favicon: "img/favicon.ico",
  organizationName: "fleaflet", // Usually your GitHub org/user name.
  projectName: "flutter_map", // Usually your repo name.
  themeConfig: {
    navbar: {
      title: "flutter_map",
      logo: {
        alt: "flutter_map logo",
        src: "img/logo.svg",
      },
      items: [
        {
          docId: "introduction/go",
          type: "doc",
          position: "left",
          label: "Docs",
        },
        {
          href: "https://github.com/fleaflet/flutter_map",
          label: "GitHub",
          position: "right",
        },
        {
          label: "Pub.dev",
          href: "https://pub.dev/packages/flutter_map",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Documentation",
          items: [
            {
              label: "Main Docs",
              to: "/introduction/go",
            },
            {
              label: "Full API Reference",
              href: 'https://pub.dev/documentation/flutter_map/latest/flutter_map/flutter_map-library.html',
            },
          ],
        },
        {
          title: "Community",
          items: [
            {
              label: "Stack Overflow",
              href: "https://stackoverflow.com/search?q=flutter_map",
            },
            {
              label: "Issues Tracker",
              href: "https://github.com/fleaflet/flutter_map/issues",
            },
            {
              label: "Pull Requests",
              href: "https://github.com/fleaflet/flutter_map/pulls",
            },
            {
              label: "Discussions",
              href: "https://github.com/fleaflet/flutter_map/discussions",
            },
          ],
        },
      ],
      copyright: `<hr>Copyright © ${new Date().getFullYear()} flutter_map<br>Built with Docusaurus.`,
    },
    prism: {
      theme: lightCodeTheme,
      darkTheme: darkCodeTheme,
      additionalLanguages: ["dart"],
    },
  },
};
