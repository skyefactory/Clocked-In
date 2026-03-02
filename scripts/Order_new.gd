extends Resource
class_name Order

var recipe: Recipe
var id: int

enum OrderStatus {
    PENDING,
    ACTIVE,
    COMPLETED
}
var status: OrderStatus = OrderStatus.PENDING
var isLate: bool = false
