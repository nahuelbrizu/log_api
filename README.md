# log_api

API REST en Ruby on Rails para **autenticación de usuarios** (email/contraseña y
login social con OAuth) y **perfiles de usuario**.

- Ruby 3.0.3 · Rails 7.0 (modo `api_only`) · MySQL
- Autenticación: [Devise](https://github.com/heartcombo/devise) + OmniAuth
  (Google, Facebook, GitHub, Twitter)
- Sesiones guardadas en base de datos (`activerecord-session_store`)
- Emails de confirmación vía SMTP (Mailgun)

## Requisitos

- Ruby 3.0.3 (ver `.ruby-version`)
- Bundler
- MySQL 5.7+ / 8

## Puesta en marcha

```bash
bundle install
cp .env.example .env      # completar con tus valores
bin/rails db:create db:migrate
bin/rails server
```

## Configuración

Todas las credenciales se leen de variables de entorno, cargadas desde `.env`
con `dotenv`. **Nunca subas `.env` al repositorio** (está en `.gitignore`).

| Variable | Uso |
| --- | --- |
| `DATABASE_USERNAME`, `DATABASE_PASSWORD` | Conexión a MySQL (desarrollo/test) |
| `APP_NAMED_POLY_DATABASE_PASSWORD` | Contraseña de MySQL en producción |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | OAuth con Google |
| `FACEBOOK_APP_ID`, `FACEBOOK_APP_SECRET` | OAuth con Facebook |
| `GITHUB_CLIENT_ID`, `GITHUB_CLIENT_SECRET` | OAuth con GitHub |
| `TWITTER_API_KEY`, `TWITTER_API_SECRET` | OAuth con Twitter |
| `MAILER_SENDER` | Remitente de los emails de Devise |
| `MAILER_DOMAIN`, `MAILER_USERNAME`, `MAILER_PASSWORD` | SMTP de Mailgun |
| `APP_HOST` | Host usado en los links de los emails (producción) |

La URL de callback que hay que registrar en cada proveedor es:

```
http://localhost:3000/users/auth/<proveedor>/callback
```

donde `<proveedor>` es `google_oauth2`, `facebook`, `github` o `twitter`.

## Endpoints

Todas las respuestas son JSON. Las rutas protegidas devuelven `401` si no hay
sesión iniciada.

### Autenticación (Devise)

| Método | Ruta | Descripción |
| --- | --- | --- |
| `POST` | `/users` | Registro (`user[email]`, `user[password]`). Envía email de confirmación |
| `GET` | `/users/confirmation?confirmation_token=...` | Confirma la cuenta |
| `POST` | `/users/sign_in` | Inicio de sesión |
| `DELETE` | `/users/sign_out` | Cierre de sesión |
| `POST` | `/users/password` | Solicita reseteo de contraseña |
| `POST` | `/users/auth/:provider` | Inicia el login OAuth |
| `GET` | `/users/auth/:provider/callback` | Callback OAuth: inicia sesión y devuelve el usuario |

**Vinculación de cuentas:** si alguien entra con OAuth usando un email que ya
existe, se vincula a esa cuenta solo si el proveedor verificó el email y la
cuenta aún no está vinculada a otro proveedor. En cualquier otro caso se
devuelve `422`.

### Perfiles (requieren sesión)

| Método | Ruta | Descripción |
| --- | --- | --- |
| `GET` | `/profiles` | Lista todos los perfiles |
| `GET` | `/profiles/:id` | Muestra un perfil |
| `POST` | `/profiles` | Crea el perfil del usuario actual (uno por usuario) |
| `PATCH/PUT` | `/profiles/:id` | Actualiza el perfil propio |
| `DELETE` | `/profiles/:id` | Elimina el perfil propio |

Campos: `profile[display_name]`, `profile[location]`, `profile[bio]`.

### Otros

| Método | Ruta | Descripción |
| --- | --- | --- |
| `GET` | `/` | Health check: `{ "status": "ok" }` |

## Tests

```bash
bundle exec rspec
```

## Pendientes conocidos

- Faltan `spec/rails_helper.rb` y `spec/spec_helper.rb`
  (`bin/rails generate rspec:install`), y los specs actuales son los del scaffold.
- `omniauth-rails_csrf_protection` exige iniciar el login OAuth con un `POST` que
  incluya un token CSRF. Como la app es solo API, falta un endpoint que entregue
  ese token, o cambiar a autenticación por tokens (por ejemplo JWT).
