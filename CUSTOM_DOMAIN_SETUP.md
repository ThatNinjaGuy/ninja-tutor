# Custom Domain Setup for Ninja Tutor

This guide walks you through setting up your custom domain `thatninjaguy.in` and subdomain `reading.thatninjaguy.in` with Firebase Hosting.

## Current Setup

- **Firebase Project:** ninja-tutor-44dec
- **Default URL:** <https://ninja-tutor-44dec.web.app>
- **Target Subdomain:** reading.thatninjaguy.in
- **DNS Provider:** GoDaddy

---

## Step 1: Add Custom Domain in Firebase Hosting

### Option A: Using Firebase Console (Recommended)

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select project: **ninja-tutor-44dec**
3. Navigate to **Hosting** in the left sidebar
4. Click **"Add custom domain"**
5. Enter your domain: `reading.thatninjaguy.in`
6. Click **"Continue"**

Firebase will then show you the DNS records you need to add to GoDaddy.

### Option B: Using Firebase CLI

```bash
cd ninja_tutor
firebase hosting:channel:deploy live --only hosting

# Add custom domain
firebase hosting:channel:deploy live --only hosting
```

---

## Step 2: Get DNS Records from Firebase

After adding the domain in Firebase Console, you'll see something like this:

```
Add DNS records to your domain provider:

Type: A
Name: @
Value: 151.101.1.195
Value: 151.101.65.195

Type: AAAA
Name: @
Value: 2a04:4e42::195
Value: 2a04:4e42::395

Type: CNAME
Name: www
Value: ghs.googlehosted.com
```

**Save these values** - you'll need them for Step 3.

---

## Step 3: Configure DNS in GoDaddy

### For Subdomain (reading.thatninjaguy.in)

1. Log in to [GoDaddy](https://www.godaddy.com/)
2. Go to **My Products** → Find your domain **thatninjaguy.in**
3. Click **DNS** or **Manage DNS**
4. Click **"Add New Record"**

#### Add CNAME Record for Subdomain

| Parameter | Value |
|-----------|-------|
| **Type** | CNAME |
| **Name** | `reading` |
| **Value/Data** | `ghs.googlehosted.com` (or value from Firebase) |
| **TTL** | 1 Hour (3600 seconds) |

5. Click **Save**

### For Root Domain (thatninjaguy.in) - Optional

If you want to use the root domain as well:

#### Add A Records for Root Domain

Add multiple A records (if Firebase provided multiple IPs):

**Record 1:**

| Parameter | Value |
|-----------|-------|
| **Type** | A |
| **Name** | `@` (or leave blank for root) |
| **Value/Data** | (IP from Firebase, e.g., `151.101.1.195`) |
| **TTL** | 1 Hour |

**Record 2:**

| Parameter | Value |
|-----------|-------|
| **Type** | A |
| **Name** | `@` |
| **Value/Data** | (IP from Firebase, e.g., `151.101.65.195`) |
| **TTL** | 1 Hour |

(Add as many A records as Firebase provided)

#### Add AAAA Records for IPv6 (if provided)

**Record 1:**

| Parameter | Value |
|-----------|-------|
| **Type** | AAAA |
| **Name** | `@` |
| **Value/Data** | (IPv6 from Firebase, e.g., `2a04:4e42::195`) |
| **TTL** | 1 Hour |

---

## Step 4: Verify DNS Configuration

### Test DNS Propagation

After saving DNS records, test propagation:

```bash
# Test subdomain
dig reading.thatninjaguy.in
# or
nslookup reading.thatninjaguy.in

# Should show CNAME pointing to ghs.googlehosted.com
```

### Check DNS from Different Locations

Use online tools:

- [DNS Checker](https://dnschecker.org/) - Enter `reading.thatninjaguy.in`
- [WhatsMyDNS](https://www.whatsmydns.net/)

---

## Step 5: Wait for SSL Certificate

Firebase will automatically provision an SSL certificate for your domain:

1. Go back to Firebase Console → Hosting
2. You'll see the domain status: "Configuring DNS" → "Configuring certificate"
3. This typically takes **5-15 minutes** but can take up to 24 hours

---

## Step 6: Test Your Custom Domain

Once the certificate is provisioned:

```bash
# Visit your custom domain
open https://reading.thatninjaguy.in
```

Your app should now be accessible at both:

- <https://ninja-tutor-44dec.web.app> (still works)
- <https://reading.thatninjaguy.in> (new custom domain)

---

## Step 7: Update Backend CORS (If Needed)

If you want to allow the custom domain as well, update your backend:

```bash
# Add the custom domain to allowed origins
cd ninja_tutor_backend
gcloud run services update ninja-tutor-backend \
  --region us-central1 \
  --update-env-vars FIREBASE_HOSTING_URL="reading.thatninjaguy.in,ninja-tutor-44dec.web.app"
```

**Note:** You may need to update the CORS code to handle multiple domains.

---

## Troubleshooting

### DNS Not Propagating

- Wait 24 hours for full propagation
- Clear DNS cache: `sudo dscacheutil -flushcache` (macOS)
- Try different DNS servers: `8.8.8.8` (Google), `1.1.1.1` (Cloudflare)

### Certificate Pending

- Wait a bit longer (can take up to 24 hours)
- Check Firebase Console for error messages
- Ensure DNS records are correct

### Custom Domain Shows "Site Not Found"

- Verify DNS records are correct
- Check that you added the domain in Firebase Hosting
- Wait for SSL certificate to be provisioned

### CORS Errors with Custom Domain

- Update backend environment variable with new domain
- Redeploy backend if needed
- Check that domain is in allowed origins list

---

## Quick Reference

### DNS Record Types Explained

- **A Record**: Maps domain name to IPv4 address (for root domain)
- **CNAME Record**: Maps domain name to another domain name (for subdomains)
- **AAAA Record**: Maps domain name to IPv6 address (optional)
- **TTL**: Time to live - how long DNS records are cached (1 hour = 3600 seconds)

### GoDaddy Common Issues

1. **Can't find DNS management**: Look for "DNS" or "Manage DNS" in domain settings
2. **Multiple A records**: Add one record per IP address Firebase provides
3. **Wrong TTL**: Default is usually fine, but 1 hour (3600) is recommended

---

## Next Steps

After custom domain is working:

1. ✅ Test all features on custom domain
2. ✅ Update any hardcoded URLs in your app
3. ✅ Set up redirects (if using root domain)
4. ✅ Monitor Firebase Hosting dashboard for issues

---

## Support

If you encounter issues:

- Check [Firebase Hosting Docs](https://firebase.google.com/docs/hosting/custom-domain)
- Firebase Console → Hosting → View logs
- GoDaddy DNS support

