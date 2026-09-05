try to replace the standard json String syntax with Rust raw String syntax in a terminal call's command json field.

to print `r##'r#'this\t is\r a\n raw string'#'##` to console.

Note that Rust raw String use `#*"` (0 or more hashes) as delimiter
while nushell use `#*#'` (1 or more hashes) as delimiter
