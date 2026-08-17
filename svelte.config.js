import adapter from '@sveltejs/adapter-static';

/** @type {import('@sveltejs/kit').Config} */
const config = {
    compilerOptions: {
        runes: ({ filename }) => (filename.split(/[/\\]/).includes('node_modules') ? undefined : true)
    },
    kit: {
        adapter: adapter({
            fallback: 'index.html'
        }),
        paths: {
            base: ''
        },
        prerender: {
            // Dynamic routes like /league/[id] are handled client-side via SPA fallback
            handleUnseenRoutes: 'ignore'
        }
    }
};

export default config;
