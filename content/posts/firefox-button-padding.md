---
title: Removing unwanted button padding in Firefox
date: 2011-09-04
image: images/firefox.png
description: 'How to remove button padding in Firefox (2011)'
tags: ['css', 'blast-from-the-past', 'firefox']
---

Recently I came across a issue with the `<button>` element in Firefox. It seems that if you have the following code:

```html
<button><span>Text</span></button>
```

..and then apply CSS styles to set padding to zero for both the elements Firefox will automatically insert padding on the button. This is impossible to remove with standard CSS.

However there is an easy fix. Just add the following rule to your button element:

```css
button::-moz-focus-inner {
    border: 0;
    padding: 0;
}
```

This should fix everything.

**Note:** I came across this post in my long forgotten Evernote account. I wrote this in 2011.
[Firefox 4](https://en.wikipedia.org/wiki/Firefox_4) was probably the version this meant to fix.