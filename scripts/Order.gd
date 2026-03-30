extends Resource
class_name Order

var recipe: Recipe # the recipe associated with this order
var id: int # the id of this order, used for tracking and UI purposes.

enum OrderStatus { # status of the order 
    PENDING,
    ACTIVE,
    COMPLETED
}
var status: OrderStatus = OrderStatus.PENDING
var isLate: bool = false # is the order late.
