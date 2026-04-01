
Object.defineProperty(exports, "__esModule", { value: true });

const {
  Decimal,
  objectEnumValues,
  makeStrictEnum,
  Public,
  getRuntime,
  skip
} = require('./runtime/index-browser.js')


const Prisma = {}

exports.Prisma = Prisma
exports.$Enums = {}

/**
 * Prisma Client JS version: 5.22.0
 * Query Engine version: 605197351a3c8bdd595af2d2a9bc3025bca48ea2
 */
Prisma.prismaVersion = {
  client: "5.22.0",
  engine: "605197351a3c8bdd595af2d2a9bc3025bca48ea2"
}

Prisma.PrismaClientKnownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientKnownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)};
Prisma.PrismaClientUnknownRequestError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientUnknownRequestError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientRustPanicError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientRustPanicError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientInitializationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientInitializationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.PrismaClientValidationError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`PrismaClientValidationError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.NotFoundError = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`NotFoundError is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.Decimal = Decimal

/**
 * Re-export of sql-template-tag
 */
Prisma.sql = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`sqltag is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.empty = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`empty is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.join = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`join is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.raw = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`raw is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.validator = Public.validator

/**
* Extensions
*/
Prisma.getExtensionContext = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.getExtensionContext is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}
Prisma.defineExtension = () => {
  const runtimeName = getRuntime().prettyName;
  throw new Error(`Extensions.defineExtension is unable to run in this browser environment, or has been bundled for the browser (running in ${runtimeName}).
In case this error is unexpected for you, please report it in https://pris.ly/prisma-prisma-bug-report`,
)}

/**
 * Shorthand utilities for JSON filtering
 */
Prisma.DbNull = objectEnumValues.instances.DbNull
Prisma.JsonNull = objectEnumValues.instances.JsonNull
Prisma.AnyNull = objectEnumValues.instances.AnyNull

Prisma.NullTypes = {
  DbNull: objectEnumValues.classes.DbNull,
  JsonNull: objectEnumValues.classes.JsonNull,
  AnyNull: objectEnumValues.classes.AnyNull
}



/**
 * Enums
 */

exports.Prisma.TransactionIsolationLevel = makeStrictEnum({
  ReadUncommitted: 'ReadUncommitted',
  ReadCommitted: 'ReadCommitted',
  RepeatableRead: 'RepeatableRead',
  Serializable: 'Serializable'
});

exports.Prisma.UserScalarFieldEnum = {
  id: 'id',
  phone: 'phone',
  email: 'email',
  googleId: 'googleId',
  name: 'name',
  role: 'role',
  language: 'language',
  profilePhoto: 'profilePhoto',
  isVerified: 'isVerified',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.SessionScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  token: 'token',
  expiresAt: 'expiresAt',
  createdAt: 'createdAt'
};

exports.Prisma.FarmerScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  village: 'village',
  taluka: 'taluka',
  district: 'district',
  state: 'state',
  pincode: 'pincode',
  latitude: 'latitude',
  longitude: 'longitude',
  farmSizeAcres: 'farmSizeAcres',
  soilType: 'soilType',
  waterSource: 'waterSource',
  currentCrops: 'currentCrops',
  bankAccountNo: 'bankAccountNo',
  ifscCode: 'ifscCode',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.SupplierScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  businessName: 'businessName',
  gstNumber: 'gstNumber',
  address: 'address',
  district: 'district',
  state: 'state',
  pincode: 'pincode',
  latitude: 'latitude',
  longitude: 'longitude',
  isVerified: 'isVerified',
  verifiedAt: 'verifiedAt',
  rejectedAt: 'rejectedAt',
  rejectedReason: 'rejectedReason',
  rating: 'rating',
  totalRatings: 'totalRatings',
  bankAccountNo: 'bankAccountNo',
  ifscCode: 'ifscCode',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.ProductScalarFieldEnum = {
  id: 'id',
  supplierId: 'supplierId',
  name: 'name',
  nameMarathi: 'nameMarathi',
  nameHindi: 'nameHindi',
  description: 'description',
  category: 'category',
  price: 'price',
  unit: 'unit',
  stockQuantity: 'stockQuantity',
  images: 'images',
  isActive: 'isActive',
  isApproved: 'isApproved',
  isOrganic: 'isOrganic',
  brand: 'brand',
  composition: 'composition',
  usageInstructions: 'usageInstructions',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.CartScalarFieldEnum = {
  id: 'id',
  farmerId: 'farmerId',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.CartItemScalarFieldEnum = {
  id: 'id',
  cartId: 'cartId',
  productId: 'productId',
  quantity: 'quantity',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.OrderScalarFieldEnum = {
  id: 'id',
  farmerId: 'farmerId',
  totalAmount: 'totalAmount',
  status: 'status',
  paymentStatus: 'paymentStatus',
  paymentId: 'paymentId',
  razorpayOrderId: 'razorpayOrderId',
  deliveryAddress: 'deliveryAddress',
  deliveryLat: 'deliveryLat',
  deliveryLng: 'deliveryLng',
  notes: 'notes',
  deliveredAt: 'deliveredAt',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.OrderItemScalarFieldEnum = {
  id: 'id',
  orderId: 'orderId',
  productId: 'productId',
  supplierId: 'supplierId',
  quantity: 'quantity',
  price: 'price',
  status: 'status',
  createdAt: 'createdAt'
};

exports.Prisma.PaymentScalarFieldEnum = {
  id: 'id',
  orderId: 'orderId',
  razorpayPaymentId: 'razorpayPaymentId',
  razorpayOrderId: 'razorpayOrderId',
  amount: 'amount',
  status: 'status',
  method: 'method',
  failureReason: 'failureReason',
  refundId: 'refundId',
  refundAmount: 'refundAmount',
  refundReason: 'refundReason',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.ReviewScalarFieldEnum = {
  id: 'id',
  orderItemId: 'orderItemId',
  productId: 'productId',
  farmerId: 'farmerId',
  rating: 'rating',
  comment: 'comment',
  createdAt: 'createdAt'
};

exports.Prisma.SoilReportScalarFieldEnum = {
  id: 'id',
  farmerId: 'farmerId',
  imageUrl: 'imageUrl',
  soilType: 'soilType',
  phLevel: 'phLevel',
  nitrogenLevel: 'nitrogenLevel',
  phosphorusLevel: 'phosphorusLevel',
  potassiumLevel: 'potassiumLevel',
  organicMatter: 'organicMatter',
  recommendedCrops: 'recommendedCrops',
  treatmentAdvice: 'treatmentAdvice',
  confidence: 'confidence',
  createdAt: 'createdAt'
};

exports.Prisma.PriceAlertScalarFieldEnum = {
  id: 'id',
  farmerId: 'farmerId',
  cropName: 'cropName',
  targetPrice: 'targetPrice',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.NotificationScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  title: 'title',
  body: 'body',
  type: 'type',
  isRead: 'isRead',
  data: 'data',
  createdAt: 'createdAt'
};

exports.Prisma.GovernmentSchemeScalarFieldEnum = {
  id: 'id',
  title: 'title',
  titleMarathi: 'titleMarathi',
  titleHindi: 'titleHindi',
  description: 'description',
  ministry: 'ministry',
  benefits: 'benefits',
  eligibility: 'eligibility',
  documents: 'documents',
  applyUrl: 'applyUrl',
  deadline: 'deadline',
  isActive: 'isActive',
  eligibleCount: 'eligibleCount',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.FCMTokenScalarFieldEnum = {
  id: 'id',
  userId: 'userId',
  token: 'token',
  device: 'device',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.DealerCropRateScalarFieldEnum = {
  id: 'id',
  supplierId: 'supplierId',
  cropName: 'cropName',
  pricePerQuintal: 'pricePerQuintal',
  district: 'district',
  isActive: 'isActive',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.TradeBookingScalarFieldEnum = {
  id: 'id',
  farmerId: 'farmerId',
  supplierId: 'supplierId',
  cropName: 'cropName',
  approxQuintals: 'approxQuintals',
  pricePerQuintal: 'pricePerQuintal',
  slotDate: 'slotDate',
  status: 'status',
  notes: 'notes',
  createdAt: 'createdAt',
  updatedAt: 'updatedAt'
};

exports.Prisma.SortOrder = {
  asc: 'asc',
  desc: 'desc'
};

exports.Prisma.NullableJsonNullValueInput = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull
};

exports.Prisma.QueryMode = {
  default: 'default',
  insensitive: 'insensitive'
};

exports.Prisma.NullsOrder = {
  first: 'first',
  last: 'last'
};

exports.Prisma.JsonNullValueFilter = {
  DbNull: Prisma.DbNull,
  JsonNull: Prisma.JsonNull,
  AnyNull: Prisma.AnyNull
};
exports.UserRole = exports.$Enums.UserRole = {
  FARMER: 'FARMER',
  SUPPLIER: 'SUPPLIER',
  ADMIN: 'ADMIN'
};

exports.ProductCategory = exports.$Enums.ProductCategory = {
  SEEDS: 'SEEDS',
  FERTILIZER: 'FERTILIZER',
  PESTICIDE: 'PESTICIDE',
  EQUIPMENT: 'EQUIPMENT',
  ORGANIC: 'ORGANIC',
  OTHER: 'OTHER'
};

exports.OrderStatus = exports.$Enums.OrderStatus = {
  PENDING: 'PENDING',
  PAYMENT_CONFIRMED: 'PAYMENT_CONFIRMED',
  PROCESSING: 'PROCESSING',
  DISPATCHED: 'DISPATCHED',
  OUT_FOR_DELIVERY: 'OUT_FOR_DELIVERY',
  DELIVERED: 'DELIVERED',
  CANCELLED: 'CANCELLED',
  REFUNDED: 'REFUNDED'
};

exports.PaymentStatus = exports.$Enums.PaymentStatus = {
  PENDING: 'PENDING',
  SUCCESS: 'SUCCESS',
  FAILED: 'FAILED',
  REFUNDED: 'REFUNDED'
};

exports.TradeStatus = exports.$Enums.TradeStatus = {
  PENDING: 'PENDING',
  ACCEPTED: 'ACCEPTED',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED'
};

exports.Prisma.ModelName = {
  User: 'User',
  Session: 'Session',
  Farmer: 'Farmer',
  Supplier: 'Supplier',
  Product: 'Product',
  Cart: 'Cart',
  CartItem: 'CartItem',
  Order: 'Order',
  OrderItem: 'OrderItem',
  Payment: 'Payment',
  Review: 'Review',
  SoilReport: 'SoilReport',
  PriceAlert: 'PriceAlert',
  Notification: 'Notification',
  GovernmentScheme: 'GovernmentScheme',
  FCMToken: 'FCMToken',
  DealerCropRate: 'DealerCropRate',
  TradeBooking: 'TradeBooking'
};

/**
 * This is a stub Prisma Client that will error at runtime if called.
 */
class PrismaClient {
  constructor() {
    return new Proxy(this, {
      get(target, prop) {
        let message
        const runtime = getRuntime()
        if (runtime.isEdge) {
          message = `PrismaClient is not configured to run in ${runtime.prettyName}. In order to run Prisma Client on edge runtime, either:
- Use Prisma Accelerate: https://pris.ly/d/accelerate
- Use Driver Adapters: https://pris.ly/d/driver-adapters
`;
        } else {
          message = 'PrismaClient is unable to run in this browser environment, or has been bundled for the browser (running in `' + runtime.prettyName + '`).'
        }
        
        message += `
If this is unexpected, please open an issue: https://pris.ly/prisma-prisma-bug-report`

        throw new Error(message)
      }
    })
  }
}

exports.PrismaClient = PrismaClient

Object.assign(exports, Prisma)
