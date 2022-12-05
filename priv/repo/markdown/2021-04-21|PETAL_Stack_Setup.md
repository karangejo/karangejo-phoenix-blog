Let's setup a new PETAL stack project! This requires a bit of boilerplate and I'm sure in the future it will be much easier. Let's get started with a new Phoenix liveview project (for the P, E and L in PETAL). First run:

```bash
mix phx.new petal_stack --live
```

OK, first order of business is to set up Tailwind css (for the T in PETAL). Run the following:

```bash
cd petal_stack/assets/
npm i tailwindcss postcss autoprefixer postcss-loader@4.2 --save-dev
```
Now we have to tell webpack about this so edit the file assets/webpack.config.js and add the following line:

```javascript
use: [
  MiniCssExtractPlugin.loader,
  'css-loader',
  'postcss-loader', // Add this
  'sass-loader',
],
```

Next create a file at assets/postcss.config.js and add the following lines:

```javascript
module.exports = {
    plugins: {
        tailwindcss: {},
        autoprefixer: {}
    }
}
```

Now we can initialize tailwind with:

```bash
npx tailwindcss init
```

And we can add the following lines to the created file at assets/tailwind.config.js

```javascript
module.exports = {
  purge: [
    '../lib/**/*.ex',
    '../lib/**/*.leex',
    '../lib/**/*.eex',
    './js/**/*.js'
  ],
  theme: {},
  variants: {},
  plugins: []
};
```
Now we also need to tell package.json about all this so edit assets/package.json and change this line:

```json
"deploy": "NODE_ENV=production webpack --mode production"
```

Now lets add the Tailwind directives. Edit the file at assets/css/app.scss:

```css
@tailwind base;

@tailwind components;

@tailwind utilities;

/* Delete this line and file as well*/
@import "./phoenix.css"; 
```

Delete the file at assets/css/phoenix.css (or leave it if you want to keep those styles) since we will be using tailwind styles.

Great! Tailwind is ready to rock! Now all that is left is the A in PETAL and that stands for alpine js. Thankfully this will require less boilerplate than tailwind. First install alpine:

```bash
cd petal_stack/assets
npm install alpinejs
```

Now lets import it into our javascript. Edit the file at assets/js/app.js:

```javascript
import Alpine from "alpinejs" // add this line

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

let liveSocket = new LiveSocket("/live", Socket, {
  params: { _csrf_token: csrfToken },
  dom: {
    onBeforeElUpdated(from, to) {
      if (from.__x) { Alpine.clone(from.__x, to) }
    }
  }
}) //add the dom: part to this object
```

Alright, PETAL stack should be up and running. All you have to do now is erase all the classes that Phoenix generated for you in the templates. Then edit the file at lib/petal_stack_web/live/page_live.html.eex:

```html
<h1 class="bg-indigo-700">Page Live</h1>  <div x-data="{ isOpen: false }">
<button @click=" isOpen = !isOpen">Toggle</button>
<h1 x-show="isOpen">Some Content</h1></div>         
```
You should see an indigo header and a functioning toogle! Enjoy the power of the PETAL.