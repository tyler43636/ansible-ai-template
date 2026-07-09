---
name: jinja2-templating
description: Author robust, safe, and cleanly formatted Jinja2 templates for Ansible.
---

# Jinja2 Templating

Use this skill when authoring or modifying `.j2` templates in `roles/*/templates/` or using inline Jinja2 in Ansible tasks.

## Best Practices

1. **Safety First**: Always provide defaults for optional variables using the `default` filter: `{{ my_var | default('fallback_value') }}`.
2. **Strict Variables**: Ansible will fail if a variable is undefined and lacks a default. Never assume a variable exists unless it is explicitly defined in `defaults/main.yml`.
3. **Whitespace Control**: Use `{%-` and `-%}` to strip leading and trailing whitespace around control structures to prevent empty lines in generated config files:
   ```jinja2
   {%- if feature_enabled -%}
   feature = true
   {%- endif -%}
   ```
4. **Booleans and Types**: Ansible boolean variables (`yes`/`no`, `true`/`false`) evaluate correctly in Jinja2 `if` statements. Do not compare them to strings (e.g., use `{% if is_enabled %}`, not `{% if is_enabled == 'yes' %}`).
5. **Data Serialization**: When writing out JSON or YAML configurations, use the built-in filters instead of manual templating: `{{ my_dict | to_nice_json }}` or `{{ my_dict | to_nice_yaml }}`.