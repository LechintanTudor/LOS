package kernel

List_Head :: distinct List_Node

List_Node :: struct {
	prev, next: ^List_Node,
}

list_init :: proc "contextless" (head: ^List_Head) {
	head.prev = (^List_Node)(head)
	head.next = (^List_Node)(head)
}

list_insert :: proc "contextless" (after, node: ^List_Node) {
	node.prev = after
	node.next = after.next
	after.next.prev = node
	after.next = node
}

list_push_front :: proc "contextless" (head: ^List_Head, node: ^List_Node) {
	list_insert((^List_Node)(head), node)
}

list_push_back :: proc "contextless" (head: ^List_Head, node: ^List_Node) {
	list_insert(head.prev, node)
}

@(require_results)
list_is_empty :: proc "contextless" (head: ^List_Head) -> bool {
	return head.next == (^List_Node)(head)
}

list_remove :: proc "contextless" (node: ^List_Node) {
	node.prev.next = node.next
	node.next.prev = node.prev
	node.prev = nil
	node.next = nil
}
