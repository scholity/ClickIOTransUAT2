/**
 * Created by jbarker on 10/24/18.
 * 03/04/2020 - cvaughan@salesforce.com - DE2597:
 *              updated createOrderItemsPost method to map cart items to order items by cart item Id. Dependent on  
 *              "Set ccrz__ItemLabel__c to Cart Item Id" WF rule populating the ccrz__ItemLabel__c field on the cart item record.
 */

global with sharing class phss_cc_hk_Order extends ccrz.cc_hk_Order {

    private static final String VOUCHER_RESERVED_STATUS     = 'Reserved';


    /**
     *
     *
     * @param inputData
     *
     * @return
     */
    global override Map<String,Object> place(Map<String,Object> inputData)
    {
        final String currentStep = (String) inputData.get(ccrz.cc_hk_Order.PARAM_PLACE_STEP);

        if (currentStep.equals(ccrz.cc_hk_Order.STEP_CREATE_ORDER_ITEMS_POST)) {
            createOrderItemsPost(inputData);
        }

        return inputData;
    }

    /**
     * Adds the ILT Class to the Order Item
     *
     * @param inputData
     */
    private void createOrderItemsPost(Map<String,Object> inputData) {

        ccrz__E_Order__c order = (ccrz__E_Order__c) inputData.get(ccrz.cc_hk_Order.PARAM_ORDER);

        List<ccrz__E_CartItem__c> cartItems = (List<ccrz__E_CartItem__c>) inputData.get(ccrz.cc_hk_Order.PARAM_CART_ITEMS);

        // build map of Cart Item Id => Cart Item
        Map<Id, ccrz__E_CartItem__c> cartItemsMap = new Map<Id, ccrz__E_CartItem__c>([
            SELECT Id, ccrz__Product__r.ccrz__SKU__c, ILT_Class__c, Coupon__c
            FROM ccrz__E_CartItem__c
            WHERE Id IN :cartItems
        ]);

        List<ccrz__E_OrderItem__c> orderItems = (List<ccrz__E_OrderItem__c>) inputData.get(ccrz.cc_hk_Order.PARAM_ORDER_ITEMS);
        
        orderItems = new List<ccrz__E_OrderItem__c>([
                SELECT ccrz__Product__r.ccrz__SKU__c, ILT_Class__c, ccrz__ItemLabel__c
                FROM ccrz__E_OrderItem__c
                WHERE Id IN :orderItems
        ]);

        // build map of Cart Item Ids to Vouchers
        final Map<Id, List<Voucher__c>> cartItemVouchersMap = new Map<Id, List<Voucher__c>>();

        List<Voucher__c> allVouchers = new List<Voucher__c>([
                SELECT Id, ILT_Class__c, CC_Cart_Item__c, CC_Order__c, CC_Order_Item__c
                FROM Voucher__c
                WHERE CC_Cart_Item__c IN :cartItems
        ]);
        
        for (Voucher__c voucher : allVouchers) {
            if(cartItemVouchersMap.containsKey(voucher.CC_Cart_Item__c)){
                cartItemVouchersMap.get(voucher.CC_Cart_Item__c).add(voucher);
            }
            else{
                cartItemVouchersMap.put(voucher.CC_Cart_Item__c, new List<Voucher__c>{voucher});
            }
        }
        
        List<SObject> recordsToUpdate = new List<SObject>();

        for(ccrz__E_OrderItem__c orderItem : orderItems){
            ccrz__E_CartItem__c cartItem;
            try{
                /*
                    DE2597: The ccrz__ItemLabel__c value on the Cart Item record is being set by WF rule "Set ccrz__ItemLabel__c to Cart Item Id".
                    The WF rule is setting the ccrz__ItemLabel__c field to "cart_item_id:"+<CartItem.Id> (ex. "cart_item_id:a5621000000F0Rx")
                    This value is automatically carried over to the Order Item record from the corresponding Cart Item when an order is placed. 
                    It is being used to map the Order Item back to the corresponding Cart Item/Vouchers in order to resolve an issue in which mutiple
                    cart items with the same Product SKU were added to the same cart but Vouchers were not being added to the correct Order Items.
                */
                Id cartItemId = Id.valueOf(orderItem.ccrz__ItemLabel__c.split(':')[1]);
                cartItem = cartItemsMap.get(cartItemId);
            }
            catch(exception ex){
                throw new phss_cc_Exception('Error parsing the ccrz__ItemLabel__c on the Order Item record. This value is derived from the ccrz__E_CartItem__c.ccrz__ItemLabel__c and set by the "Set ccrz__ItemLabel__c to Cart Item Id" WF rule.');
            }
            if(cartItem != null){
                if(cartItem.Coupon__c != null || cartItem.ILT_Class__c != null){
                    orderItem.Coupon__c = String.isNotBlank(cartItem.Coupon__c) ? cartItem.Coupon__c : null;
                    orderItem.Coupon_Used__c = String.isNotBlank(cartItem.Coupon__c) ? true : false;
                    orderItem.ILT_Class__c = String.isNotBlank(cartItem.ILT_Class__c) ? cartItem.ILT_Class__c : null;
                    recordsToUpdate.add(orderItem);
                }
                if(cartItemVouchersMap.containsKey(cartItem.Id)){
                    for(Voucher__c voucher : cartItemVouchersMap.get(cartItem.Id)){
                        voucher.Status__c = VOUCHER_RESERVED_STATUS;
                        voucher.CC_Order__c = order.Id;
                        voucher.CC_Order_Item__c = orderItem.Id;
                        recordsToUpdate.add(voucher);
                    }
                }
            }
        }
        if(!recordsToUpdate.isEmpty()){
            update recordsToUpdate;
        }
    }

}