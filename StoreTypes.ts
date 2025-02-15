export type Product = {
    name: string;
    id: number;
    price: number;
    amount: number;
    creator: string;
  };
export type DiscountTicket = {
  discount: number;
  amount: number;
  id: number;
  user: string;
}