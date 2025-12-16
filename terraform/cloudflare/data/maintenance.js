// template_hash ${template_hash}

addEventListener("fetch", event => {
  event.respondWith(fetchAndReplace(event.request))
})

async function fetchAndReplace(request) {

  let modifiedHeaders = new Headers()

  modifiedHeaders.set('Content-Type', 'text/html; charset=utf-8')
  modifiedHeaders.append('Pragma', 'no-cache')

  // Return modified response.
  return new Response(maintenancePage, {
    status: 503,
    headers: modifiedHeaders
  })
}

const maintenancePage = `
<!doctype html>

<head>
    <meta charset="utf-8">
    <title>Site Maintenance</title>

    <link href="https://fonts.googleapis.com/css2?family=${font}&display=swap" rel="stylesheet"/>
    <meta content="width=device-width, initial-scale=1" name="viewport" />
    <link rel="icon" href="${favicon_url}"/>
    <style>
        body {
            text-align: center;
            font-family: "${font}", sans-serif;
            color: #0C1231;
        }

        .logo {
            margin-top: 3rem;
            max-height: 100px;
            width: auto;
        }

        .content {
            margin: 0 auto;
            max-width: 1000px;
            width: 90%;
        }

        .info {
            margin: 0 auto;
            // margin-top: 1rem;
            max-width: 500px;
        }

        h1 {
            font-weight: 600;
            font-size: 1.8rem;
        }

        .image-main {
            // margin-top: 1rem;
            max-width: 90%;
        }

        hr {
            border: 1px solid rgba(0, 0, 0, 0.08);

            margin: 0 auto;
            margin-top: 2rem;
            margin-bottom: 1rem;
            max-width: 90%;
        }

        a {
            text-decoration: none;
            color: #535353
        }

        a:hover {
            color: #0C1231;
        }

        @media (min-width: 968px) {
            .logo {
                max-height: 100px;
            }

            h1 {
                font-size: 2.5rem;
            }

            .info {
                margin-top: 1rem;
            }

            hr {
                margin-top: 6rem;
                margin-bottom: 3rem;
            }
        }
    </style>
</head>

<body>
    <div class="content">
        <img class="logo" src="${logo_url}" alt="${header}">
        <div class="info">
            ${info_html}
            <p>&mdash; ${name}</p>
        </div>
        %{ if image_url != "" }
        <img class="image-main" src="${image_url}" alt="Maintenance image">
        %{ endif }
        <hr />
        <a href="mailto:${email}?subject=Maintenance">You can reach me at: ${email}</a>
    </div>
</body>
`;
