# About this Image

Images built from this repository are used as bases for serving Drupal 8 websites. They differ from the Docker Hub's `drupal` image in two ways:

1. These images do not include a copy of the Drupal 8 sources. We expect users of this image to add Drupal via Composer in a build step (or via a bind-mount during local development).
2. These images include a small utility, `f1-ext-install`, to simplify the task of installing common extensions. For example, to install Memcached, one only needs to add this to their Dockerfile:

   ```sh
   f1-ext-install pecl:memcached
   ```

# License

Like the [base PHP image](https://github.com/docker-library/php) we use, this project is available under the terms of the MIT license. See [LICENSE](LICENSE) for more details.
