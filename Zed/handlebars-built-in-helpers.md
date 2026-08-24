#### Built-in Helpers

<!--Source: https://docs.rs/handlebars/latest/src/handlebars/lib.rs.html#342-368-->

- `{{{{raw}}}} ... {{{{/raw}}}}` escape handlebars expression within the block
- `{{#if ...}} ... {{else}} ... {{/if}}` if-else block
- `{{#unless ...}} ... {{else}} .. {{/unless}}` if-not-else block
- `{{#each ...}} ... {{/each}}` iterates over an array or object. Handlebars-rust doesn't support mustache iteration syntax so use `each` instead.
- `{{#with ...}} ... {{/with}}` change current context. Similar to `{{#each}}`, used for replace corresponding mustache syntax.
- `{{lookup ... ...}}` get value from array by `@index` or `@key`
  (See [the handlebarjs documentation](https://handlebarsjs.com/guide/builtin-helpers.html) on how to use helpers above.)
- `{{> ...}}` include template by its name
- `{{log ...}}` log value with rust logger, default level: INFO. Currently you cannot change the level.
- Boolean helpers that can be used in `if` as subexpression, for example `{{#if (gt 2 1)}} ...`:
  - `eq`
  - `ne`
  - `gt`
  - `gte`
  - `lt`
  - `lte`
  - `and`
  - `or`
  - `not`
- `{{len ...}}` returns length of array/object/string
