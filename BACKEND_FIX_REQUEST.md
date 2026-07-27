# Fix Request: Add `store.slug` to Product API Response

## 🔴 URGENT: Mobile App Navigation Broken

### Problem
Mobile app tidak bisa navigate dari product detail ke store detail page karena API response tidak include `store.slug` field.

### Current API Response (❌ Broken)
```json
GET /api/products

{
  "success": true,
  "data": {
    "items": [
      {
        "name": "Gentong jawa tali air #EL-011",
        "store": {
          "name": "ELmojo Antique",
          "province": "JAWA TIMUR",
          "isVerified": false,
          "rating": 0
          // ❌ Missing: "slug" field
        }
      }
    ]
  }
}
```

### Expected API Response (✅ Fixed)
```json
GET /api/products

{
  "success": true,
  "data": {
    "items": [
      {
        "name": "Gentong jawa tali air #EL-011",
        "store": {
          "name": "ELmojo Antique",
          "slug": "elmojo-antique",  // ✅ ADD THIS
          "province": "JAWA TIMUR",
          "isVerified": false,
          "rating": 0,
          "logoUrl": null,           // ✅ RECOMMENDED (optional)
          "totalSold": 0             // ✅ RECOMMENDED (optional)
        }
      }
    ]
  }
}
```

---

## 🔧 Required Fix

### File to Edit: `src/app/api/products/route.ts`

**Current Code:**
```typescript
store: {
  select: {
    name: true,
    province: true,
    isVerified: true,
    rating: true,
  }
}
```

**Updated Code (ADD 3 FIELDS):**
```typescript
store: {
  select: {
    name: true,
    slug: true,        // ✅ CRITICAL: Needed for mobile navigation
    province: true,
    isVerified: true,
    rating: true,
    logoUrl: true,     // ✅ RECOMMENDED: For store avatar
    totalSold: true,   // ✅ RECOMMENDED: For store stats
  }
}
```

---

## 📋 Complete Implementation Example

```typescript
// File: src/app/api/products/route.ts

export async function GET(req: NextRequest) {
  // ... existing code ...
  
  const products = await prisma.product.findMany({
    where: {
      // ... existing filters ...
    },
    select: {
      id: true,
      name: true,
      slug: true,
      price: true,
      // ... other product fields ...
      
      store: {
        select: {
          name: true,
          slug: true,        // ✅ ADD THIS
          province: true,
          city: true,        // Optional but helpful
          isVerified: true,
          rating: true,
          logoUrl: true,     // ✅ ADD THIS
          totalSold: true,   // ✅ ADD THIS
        }
      },
      
      // ... other relations ...
    }
  });
  
  return ok({
    items: products,
    total,
    page,
    limit,
    pages: Math.ceil(total / limit),
  });
}
```

---

## ✅ Testing

After fix, test with:
```bash
curl https://majacraft.id/api/products?limit=1

# Should return store object with "slug" field:
# {
#   "store": {
#     "name": "ELmojo Antique",
#     "slug": "elmojo-antique",  ← This must exist
#     ...
#   }
# }
```

---

## 🎯 Why This is Critical

1. **Store Detail Endpoint Already Exists**: `/api/stores/[slug]` is working
2. **Mobile UI Already Built**: StoreDetailScreen ready
3. **Missing Link**: Mobile app needs `store.slug` to build URL `/api/stores/elmojo-antique`

Without `slug`, the "Kunjungi Toko" button cannot navigate to store page.

---

## 📝 Summary

**What to do:** Add `slug: true` to store select in `/api/products` route
**Why:** Enable mobile app navigation from product → store detail
**Impact:** Mobile app feature currently broken, will work after this fix
**Effort:** 5 minutes (add 1 line of code)
**Priority:** HIGH (blocking mobile app feature)

---

## 🙏 Request

Tolong tambahkan field `slug` (dan optional: `logoUrl`, `totalSold`) ke store object di response API `/api/products` ya. Mobile app sudah siap, tinggal tunggu field ini aja.

Terima kasih! 🙏
