// Documentation site. Content settings (title, description, sidebar) are in site.json; where
// the site is published comes from the pipeline (.github/workflows/pages.yml):
//   SITE_ORIGIN, SITE_BASE_PATH   outputs of actions/configure-pages
//   GITHUB_SERVER_URL, GITHUB_REPOSITORY, SITE_BRANCH   the repository, for the GitHub and edit links
// Without them (npm run dev), the site is served at the root, without those links.
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import starlightLinksValidator from 'starlight-links-validator';
import config from './site.json' with { type: 'json' };

const env = process.env;
const repository = env.GITHUB_REPOSITORY ? `${env.GITHUB_SERVER_URL}/${env.GITHUB_REPOSITORY}` : undefined;

export default defineConfig({
  site: env.SITE_ORIGIN || undefined,
  base: env.SITE_BASE_PATH || '/',
  integrations: [
    starlight({
      title: config.title,
      description: config.description,
      customCss: config.customCss,
      social: repository ? [{ icon: 'github', label: 'GitHub', href: repository }] : [],
      editLink: repository && env.SITE_BRANCH ? { baseUrl: `${repository}/edit/${env.SITE_BRANCH}/docs/` } : undefined,
      lastUpdated: true,
      // links between pages are relative, so the site works under any base path
      plugins: [starlightLinksValidator({ errorOnRelativeLinks: false })],
      sidebar: config.sidebar,
    }),
  ],
});
