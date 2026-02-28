# 安装手册

## 安装 hugo

```bash
go install github.com/gohugoio/hugo@latest
```

## 安装 Algolia

Follow this tutorial to create your index in Algolia. The index is just the storage of the indexing data of your site in the the cloud . The search page of CleanWhite theme will utilize this indexing data to do the search.
Go to the directory where you have your Hugo site and run the following commands:

```bash
$ npm init
$ npm install atomic-algolia --save
```

Next, open up the newly created package.json, where we’ll add an NPM script to update your index at Algolia. Find "scripts", and add the following:

```json
"algolia": "atomic-algolia"
```

Algolia index output format has already been supported by the CleanWhite theme, so you can just build your site, then you’ll find a file called algolia.json in your public directory, which we can use to update your index in Algolia. Generate index file:

```bash
$ hugo
```

Create a new file in the root of your Hugo project called .env, and add the following contents:

```env
ALGOLIA_APP_ID={{ YOUR_APP_ID }}
ALGOLIA_ADMIN_KEY={{ YOUR_ADMIN_KEY }}
ALGOLIA_INDEX_NAME={{ YOUR_INDEX_NAME }}
ALGOLIA_INDEX_FILE={{ PATH/TO/algolia.json }}
```

Make sure double curly braces be replaced together.

Now you can push your index to Algolia by simply running:

```bash
$ npm run algolia
```

Add the following variables to your hugo site config so the search page can get access to algolia index data in the cloud:

```toml
algolia_search = true
algolia_appId = {{ YOUR_APP_ID }}
algolia_indexName = {{ YOUR_INDEX_NAME }}
algolia_apiKey = {{ YOUR_SEARCH_ONLY_KEY }}
```

Open search page in your browser: http://localhost:1313/search