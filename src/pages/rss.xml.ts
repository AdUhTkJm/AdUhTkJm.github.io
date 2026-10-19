import rss from "@astrojs/rss";
import { getAllArticles } from "@/lib/articles";
import config from "@/config";

export async function GET() {
  const articles = await getAllArticles(config.site.lang);

  return rss({
    title: config.site.title,
    description: config.site.description,
    site: config.site.url,
    items: articles.map(article => ({
      link: new URL(article.href, config.site.url).href,
      title: article.title,
      description: article.description,
      ...(article.date ? { pubDate: article.date } : {}),
    })),
  });
}
