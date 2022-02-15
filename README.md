# tsak.dev

Look mum, I have a blog.

## Prerequisites

- [Hugo](https://gohugo.io/) (tested with 0.80)
- [GNU make](https://www.gnu.org/software/make/)

## Usage

### Write

Run Hugo in local development mode on [localhost:1313](http://localhost:1313/)

```bash
make write
```

### Build

Generate site in `public`

```bash
make build
```

### Publish

Rsync generated site

```bash
make publish
```

### Clean

Delete `public` and `resources/_gen`

```bash
make clean
```