# SSL Configuration

Some requests from the game client to the server (`api.playstrife.gg`) need to be encrypted for security reasons, e.g. the retrieval of a new **Session Key** for **API** requests. This requires

- a valid **SSL Certificate** on the server and
- a current `ca-bundle.crt` file on the client which contains the **Public Key** of the **Certification Authority (CA)** issuing the server certificate.

Since the **Strife** game client falls back to unencrypted `HTTP` when it fails to verify the server certificate, this allows for a **man-in-the-middle attack** to (for example)
**hijack** an existing connection to the **API** by making the server generate a new **Session Key** using a *sniffed* **Authentication Token**.

Hence we need to establish a procedure which maintains a valid **SSL Configuration** and to document our actions using a **Changelog** like the following.

## Changelog

- `2025-09-13`: Update server certificate
    - CA: **Let's Encrypt (E7)**
    - Expiration: `2025-12-12`
- `2025-09-16-`: Download/Update `cacert.pem -> ca-bundle.crt` to/in `strife-patches` repository (here)
    - Source: https://curl.se/docs/caextract.html
    - Version/Link: [`2025-09-09`](https://curl.se/ca/cacert.pem)
- `YYYY-MM-DD`: Update `ca-bundle.crt` on all game clients via **Steam**.
    - Patch-Version: `1.1.5.X`