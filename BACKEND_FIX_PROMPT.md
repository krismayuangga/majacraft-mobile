# Backend Fix: Studio Products DELETE Endpoint

## 🐛 Problem Report

**Endpoint:** `DELETE /api/studio/products/[id]`  
**File:** `src/app/api/studio/products/[id]/route.ts`  
**Issue:** Returns HTTP 500 error when deleting products with foreign key constraints (order items, cart items, wishlist, product images, reviews)

### Current Behavior:
- Mobile app tries to delete product
- Backend throws unhandled Prisma error due to foreign key constraints
- Returns 500 Internal Server Error instead of proper error handling
- No validation for products with order history

### Expected Behavior:
- Check if product has order history → return 409 with clear message
- Properly delete related records before deleting product
- Return 200 with success message
- Match the implementation in admin DELETE endpoint

## 📝 Current Implementation

```typescript
// src/app/api/studio/products/[id]/route.ts (CURRENT - BROKEN)
export async function DELETE(_req: NextRequest, { params }: Params) {
  const { session, error } = await requireAuth();
  if (error) return error;
  const { id } = await params;

  const store = await prisma.store.findUnique({ where: { userId: session!.user!.id! } });
  if (!store) return err("Toko tidak ditemukan", 404);

  const product = await prisma.product.findUnique({ where: { id } });
  if (!product || product.storeId !== store.id) return err("Produk tidak ditemukan", 404);

  // ⚠️ PROBLEM: Langsung delete tanpa handle foreign key constraints!
  await prisma.product.delete({ where: { id } });
  return ok({ deleted: true });
}
```

## ✅ Solution

Update the DELETE endpoint to match the admin version with proper constraint handling:

```typescript
// src/app/api/studio/products/[id]/route.ts (FIXED VERSION)
export async function DELETE(_req: NextRequest, { params }: Params) {
  const { session, error } = await requireAuth();
  if (error) return error;
  const { id } = await params;

  const store = await prisma.store.findUnique({ where: { userId: session!.user!.id! } });
  if (!store) return err("Toko tidak ditemukan", 404);

  // ✅ Include _count to check for order history
  const product = await prisma.product.findUnique({
    where: { id },
    include: { _count: { select: { orderItems: true } } },
  });

  if (!product || product.storeId !== store.id) {
    return err("Produk tidak ditemukan", 404);
  }

  // ✅ Prevent deletion if product has order history (data integrity)
  if (product._count.orderItems > 0) {
    return err(
      "Produk tidak bisa dihapus karena memiliki riwayat pesanan. Gunakan toggle aktif/nonaktif untuk menyembunyikan produk.",
      409
    );
  }

  // ✅ Delete related records manually (in case onDelete cascade not configured)
  await prisma.productImage.deleteMany({ where: { productId: id } });
  await prisma.cartItem.deleteMany({ where: { productId: id } });
  await prisma.wishlist.deleteMany({ where: { productId: id } });

  // ✅ Now safe to delete the product
  await prisma.product.delete({ where: { id } });

  return ok({ deleted: true, message: "Produk berhasil dihapus" });
}
```

## 🎯 Implementation Checklist

Please implement the following changes:

- [ ] Update `src/app/api/studio/products/[id]/route.ts` DELETE handler
- [ ] Add `_count` include to check for orderItems
- [ ] Add validation: return 409 if product has order history
- [ ] Add manual deletion of related records (productImage, cartItem, wishlist)
- [ ] Test with:
  - [ ] Product without orders (should succeed)
  - [ ] Product with orders (should return 409)
  - [ ] Product with images/cart/wishlist (should succeed)
- [ ] Verify mobile app can now handle the response properly

## 📚 Reference

The admin DELETE endpoint already has the correct implementation:
- **File:** `src/app/api/admin/products/[id]/route.ts`
- **Lines:** 29-54

## 🔍 Testing Steps

After fix is deployed:

1. **Test Case 1: Delete product without orders**
   ```bash
   DELETE /api/studio/products/{new_product_id}
   Authorization: Bearer {seller_token}
   
   Expected: 200 OK
   Response: { "success": true, "data": { "deleted": true, "message": "..." } }
   ```

2. **Test Case 2: Delete product with order history**
   ```bash
   DELETE /api/studio/products/{product_with_orders_id}
   Authorization: Bearer {seller_token}
   
   Expected: 409 Conflict
   Response: { "success": false, "error": "Produk tidak bisa dihapus karena memiliki riwayat pesanan..." }
   ```

3. **Test Case 3: Flutter app integration**
   - Open Studio Seniman → Karya Saya
   - Try to delete a new product → Should succeed
   - Try to delete product with orders → Should show proper error message

## 💬 Additional Notes

- This matches the documented behavior in `halaman-studio.md` line 112: "Produk dengan riwayat pesanan tidak bisa dihapus (error 409)"
- Flutter app already updated to handle both success and error responses properly
- The fix maintains data integrity while providing clear error messages to sellers

## 📱 Mobile App Status

✅ Flutter app (`lib/services/api_service.dart`) already updated to handle:
- Success responses with `success: true`
- Error responses with `success: false` and error message
- HTTP 409 conflict responses properly

Waiting for backend fix to complete the implementation.

---

**Priority:** High  
**Impact:** Prevents sellers from managing their products properly  
**Estimated Time:** 15-20 minutes  
**Risk:** Low (follows existing admin implementation pattern)
