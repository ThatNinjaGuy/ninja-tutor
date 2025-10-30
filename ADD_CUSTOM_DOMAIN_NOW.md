# Quick Guide: Add Custom Domain Now

## Step 1: Open Firebase Console

1. Go to: <https://console.firebase.google.com/project/ninja-tutor-44dec/hosting>
2. Or manually: Firebase Console → Project: ninja-tutor-44dec → Hosting (left sidebar)

## Step 2: Click "Add custom domain"

You'll see a button/link that says **"Add custom domain"** or **"Connect domain"**

## Step 3: Enter Your Domain

- Enter: `reading.thatninjaguy.in`
- Click **Continue** or **Next**

## Step 4: Get DNS Records

Firebase will show you the DNS records you need to add. It will look something like this:

```
┌──────┬───────┬──────────────────────────────┐
│ Type │ Name  │ Value                        │
├──────┼───────┼──────────────────────────────┤
│ CNAME│ reading│ ghs.googlehosted.com        │
└──────┴───────┴──────────────────────────────┘
```

**Copy these values** - you'll need them for GoDaddy.

## Step 5: Add DNS Record in GoDaddy

1. Go to: <https://dcc.godaddy.com/manage/thatninjaguy.in/dns>
2. Click **"Add"** button
3. Select **CNAME** from the dropdown
4. Fill in:
   - **Name/Host**: `reading`
   - **Value/Points to**: `ghs.googlehosted.com` (or whatever Firebase showed)
   - **TTL**: `1 Hour` (or leave default)
5. Click **Save**

## Step 6: Wait for Verification

- Go back to Firebase Console
- Firebase will verify your DNS configuration (usually 1-15 minutes)
- Status will change from "Pending" → "Connected"
- SSL certificate will be provisioned automatically (5-30 minutes)

## Step 7: Test

Once status shows "Connected" and certificate is ready:

Visit: <https://reading.thatninjaguy.in>

---

## What Firebase Will Show You

After you enter your domain, Firebase will display something like:

```
Add the following DNS record to complete setup:

Type: CNAME
Host: reading
Value: ghs.googlehosted.com
```

**This is what you'll copy to GoDaddy.**

---

## Common Questions

**Q: Can I use the root domain (thatninjaguy.in) instead?**
A: Yes! Use `@` as the Host/Name field in GoDaddy for root domain, and Firebase will give you A records instead of CNAME.

**Q: How long until it works?**
A: DNS: 5-30 minutes. SSL Certificate: 15 minutes to 2 hours.

**Q: Will the old URL (ninja-tutor-44dec.web.app) still work?**
A: Yes! Both URLs will work.

---

## Need Help?

If you get stuck at any step, check:

1. Firebase Console → Hosting → Your domain → See status/errors
2. GoDaddy DNS → Verify the record was added correctly
3. Run: `nslookup reading.thatninjaguy.in` to test DNS propagation


