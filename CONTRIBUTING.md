## Contributing

To add a lab:
1. Fork this repository so you can make local changes.

2. Create a new directory under the `/labs` directory in this repo. For example:
```
/labs/new-awesome-tutorial
```

3. Insert your content in a `README.md` file. For example:

In: `/labs/new-awesome-tutorial/README.md`
```
# Tutorial
This is the whole tutorial!
```

If you are creating new content, use the [new-content](./templates/new-content/README.md) README.md template.

If you are linking to existing content, use the [link-to-existing](./templates/link-to-existing-content/README.md) README.md template.

Note: If you include any links or screenshots in your post, ensure the link is an absolute url rather than a url that points to a relative location on this repository. You can convert any relative link to this repository to an absolute link by prefixing the relative link with `https://raw.githubusercontent.com/optimizely/labs/master/` for images and `https://github.com/optimizely/labs/master/` for any other content. For example: a relative link to `./templates/new-content/README.md` would become: `https://github.com/optimizely/labs/blob/master/templates/new-content/README.md`

4. Add a `metadata.md` file to contain metadata about your tutorial following the [metadata](./templates/metadata.md)
   template.

For example, in: `/labs/new-awesome-tutorial/metadata.md`:
```
---
title: 'Awesome Tutorial'
summary: 'Description of the awesome tutorial'
revisionDate: '2020-03-16'
labels:
  - data

author:
  name: Asa Schachar
  headshot: '/assets/authors/asa.jpeg'
  bio: ''
  title: ''
  company: ''

seo:
  title: ''
  description: ''
  ogTitle: ''
  ogDescription: ''
  ogImage: '/assets/images/enriched_events.png'
  twitterImage: ''
  noindex: false
---
```
5. Submit your changes as a pull request to get reviewed and merged by the Optimizely team.

6. Profit 🎉
